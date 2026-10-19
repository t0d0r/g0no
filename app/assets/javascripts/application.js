// Page behaviour for g0No. Plain JavaScript plus Turbo Drive (turbo-rails),
// which swaps the <body> on link clicks and form submits instead of loading
// a new page. This file runs once; setUpPage runs on every turbo:load.
// Listeners on document or window that belong to one page pass
// { signal: pageSignal }, so they are removed when the next page loads.
let pageAbort = null;
let pageSignal;
// Functions that say whether the page has work in progress that a live
// refresh would throw away (see setUpLiveRefresh); reset on every page.
let busyChecks = [];

// Requests made with Turbo's fetch carry an X-Turbo-Request-Id that Turbo
// remembers, so the live refresh caused by this page's own save is skipped.
const turboFetch = (...args) => (window.Turbo?.fetch ?? window.fetch)(...args);

// Text areas grow with their text instead of scrolling. scrollHeight leaves
// out the border, which with border-box sizing would leave the box a pixel
// short and bring back the scroll bar. Overflow is hidden on both axes: the
// text always wraps, and with the Big / Extra big zoom rounding can make the
// content a fraction wider than the box. Without JavaScript the field keeps
// its normal scroll bar, so no text is hidden.
function autoGrow(textarea) {
  textarea.style.overflow = "hidden";
  // Measuring needs height "auto" for a moment, which shrinks a long page
  // and makes the browser pull the scroll position up; put it back.
  const grow = () => {
    const scrollY = window.scrollY;
    textarea.style.height = "auto";
    const border = textarea.offsetHeight - textarea.clientHeight;
    textarea.style.height = `${textarea.scrollHeight + border}px`;
    if (window.scrollY !== scrollY) window.scrollTo(window.scrollX, scrollY);
  };
  textarea.addEventListener("input", grow);
  // Sent when a hidden text area is shown again (Markdown notes).
  textarea.addEventListener("autogrow", grow);
  window.addEventListener("resize", grow, { signal: pageSignal });
  document.fonts?.ready.then(grow);
  // The text size buttons change data-scale on <html>; the wrap changes with it.
  const observer = new MutationObserver(grow);
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ["data-scale"] });
  pageSignal.addEventListener("abort", () => observer.disconnect());
  grow();
}

// Viewport y of the middle of the line holding `position` in a text area:
// a hidden copy with the same box and font gets the text up to that point
// and a marker. Rectangles (not offsets) keep it right under the text size
// zoom.
function caretClientY(textarea, position) {
  const style = getComputedStyle(textarea);
  const mirror = document.createElement("div");
  for (const property of ["boxSizing", "width", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft",
                          "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth",
                          "fontFamily", "fontSize", "fontWeight", "fontStyle", "letterSpacing", "lineHeight",
                          "wordSpacing", "tabSize", "textTransform"]) {
    mirror.style[property] = style[property];
  }
  Object.assign(mirror.style, {
    position: "absolute", top: "0", left: "-10000px", visibility: "hidden",
    whiteSpace: "pre-wrap", overflowWrap: "break-word", borderStyle: "solid"
  });
  mirror.textContent = textarea.value.slice(0, position);
  const marker = document.createElement("span");
  marker.textContent = "\u200b";
  mirror.append(marker);
  document.body.append(mirror);
  const mirrorRect = mirror.getBoundingClientRect();
  const markerRect = marker.getBoundingClientRect();
  mirror.remove();
  return textarea.getBoundingClientRect().top + (markerRect.top - mirrorRect.top) + markerRect.height / 2;
}

// Copies the note's text (or its title when there is no text) to the
// clipboard. navigator.clipboard needs HTTPS or localhost; elsewhere a
// hidden text area and execCommand do the job.
async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    const scratch = document.createElement("textarea");
    scratch.value = text;
    scratch.setAttribute("readonly", "");
    scratch.style.position = "fixed";
    scratch.style.opacity = "0";
    document.body.append(scratch);
    scratch.select();
    document.execCommand("copy");
    scratch.remove();
  }
}

function setUpCopyNote(button) {
  const read = (selector) => {
    const element = document.querySelector(selector);
    if (!element) return "";
    return ("value" in element ? element.value : element.textContent).trim();
  };
  button.hidden = false;
  button.addEventListener("click", async () => {
    const text = read(button.dataset.copyText) || read(button.dataset.copyTitle);
    if (!text) return;
    await copyText(text);
    button.classList.add("is-copied");
    button.title = button.dataset.copied;
    setTimeout(() => {
      button.classList.remove("is-copied");
      button.title = button.dataset.label;
    }, 1500);
  });
}

// Notes save themselves, like Stickies: shortly after typing stops, when a
// field loses focus, and when the page is left. A new note is created once
// it has a title; after that the form updates it.
function setUpNoteForm(form) {
  const title = form.querySelector(".note-title");
  const status = form.querySelector("[data-autosave-status]");
  const fields = form.querySelectorAll(".note-title, .note-description, [data-color-choice]");
  let saved = new FormData(form);
  let timer = null;
  let saving = false;
  let again = false;

  const say = (text, failed = false) => {
    if (!status) return;
    status.textContent = text;
    status.classList.toggle("note-autosave__status--failed", failed);
  };
  const dirty = () => {
    const now = new FormData(form);
    return ["note[title]", "note[description]", "note[color]"].some((key) => now.get(key) !== saved.get(key));
  };
  const isNew = () => !form.querySelector("input[name=_method]");

  // The form's own token is bound to its original action (Rails per-form
  // tokens), which changes once a new note is created; the page-wide token
  // from the csrf-token meta tag is valid for any action.
  // An existing note sends only the fields that changed, so saving the text
  // does not put back a colour someone else changed meanwhile.
  const formData = (snapshot) => {
    const body = new FormData(form);
    const token = document.querySelector("meta[name=csrf-token]");
    if (token) body.set("authenticity_token", token.content);
    if (!isNew()) {
      ["note[title]", "note[description]", "note[color]"].forEach((key) => {
        if (snapshot.get(key) === saved.get(key)) body.delete(key);
      });
    }
    return body;
  };

  // A created note continues as an update of that note.
  const becomeExisting = (url) => {
    form.action = url;
    const method = document.createElement("input");
    Object.assign(method, { type: "hidden", name: "_method", value: "patch" });
    form.prepend(method);
    history.replaceState(history.state, "", url); // keeps Turbo's restoration state
  };

  const save = async () => {
    clearTimeout(timer);
    timer = null;
    if (!dirty()) return;
    if (!title.value.trim()) {
      say(form.dataset.needsTitle, true);
      return;
    }
    if (saving) {
      again = true;
      return;
    }
    saving = true;
    const snapshot = new FormData(form);
    const body = formData(snapshot);
    say(form.dataset.saving);
    try {
      const response = await turboFetch(form.action, {
        method: "POST",
        body,
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(data.error || response.statusText);
      saved = snapshot;
      if (isNew()) becomeExisting(data.url);
      const view = form.querySelector("[data-markdown-view]");
      // Rendered and sanitized by the server (MarkdownHelper).
      if (view && typeof data.html === "string") view.innerHTML = data.html;
      say(`${form.dataset.saved} ${data.saved_at}`);
    } catch (error) {
      say(`${form.dataset.failed} ${error.message}`, true);
    } finally {
      saving = false;
      if (again) {
        again = false;
        save();
      }
    }
  };

  fields.forEach((field) => {
    field.addEventListener("input", () => {
      clearTimeout(timer);
      timer = setTimeout(save, 1200);
    });
    field.addEventListener("change", save);
    field.addEventListener("blur", save);
  });

  // Leaving the page (a link, the colour menu, closing the tab): send what is
  // left with keepalive so the request outlives the page.
  const flush = () => {
    if (!dirty() || !title.value.trim()) return;
    const snapshot = new FormData(form);
    turboFetch(form.action, { method: "POST", body: formData(snapshot), keepalive: true, headers: { Accept: "application/json" },
                              credentials: "same-origin" });
    saved = snapshot;
  };
  window.addEventListener("pagehide", flush, { signal: pageSignal });
  document.addEventListener("visibilitychange", () => { if (document.visibilityState === "hidden") flush(); },
                            { signal: pageSignal });
  // A Turbo visit or form submit leaves the page without a pagehide.
  document.addEventListener("turbo:visit", flush, { signal: pageSignal });
  document.addEventListener("turbo:submit-start", flush, { signal: pageSignal });

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    save();
  });

  setUpNoteLock(form, { save, say });

  // Unlocked for editing, typed but not saved yet, or saving.
  busyChecks.push(() => !form.classList.contains("is-locked") || dirty() || saving);

  title.addEventListener("input", () => {
    document.title = title.value ? `g0No - ${title.value}` : "g0No";
  });
}

// A saved note opens locked: its text can be selected and copied, but a
// single click does not edit it. A double-click (or the padlock box, or
// Enter on a locked field) unlocks it; leaving the fields or pressing Escape
// saves and locks it again.
function setUpNoteLock(form, { save, say }) {
  if (form.dataset.lockable !== "true") return;
  const fields = [...form.querySelectorAll(".note-title, .note-description")];
  const description = form.querySelector(".note-description");
  const view = form.querySelector("[data-markdown-view]");
  const windowEl = form.closest(".note-window");
  const box = windowEl?.querySelector("[data-lock-box]");
  let locked = false;

  // Markdown notes: formatted while locked, plain text while editing.
  const showFormatted = (formatted) => {
    if (!view) return;
    view.hidden = !formatted;
    description.hidden = formatted;
    if (!formatted) description.dispatchEvent(new Event("autogrow"));
  };

  // A task list box clicked in the formatted view flips "[ ]" / "[x]" on its
  // line of the text (data-task-line) and saves.
  const toggleTask = (checkbox) => {
    const lines = description.value.split("\n");
    const index = Number(checkbox.dataset.taskLine) - 1;
    const marker = /^(\s*(?:>\s*)*(?:[-+*]|\d+[.)])\s+)\[[ xX]\]/;
    if (!marker.test(lines[index] ?? "")) {
      checkbox.checked = !checkbox.checked;
      return;
    }
    lines[index] = lines[index].replace(marker, `$1[${checkbox.checked ? "x" : " "}]`);
    description.value = lines.join("\n");
    save();
  };

  const show = () => {
    windowEl?.classList.toggle("is-editing", !locked);
    form.classList.toggle("is-locked", locked);
    if (box) {
      box.hidden = false;
      box.classList.toggle("is-locked", locked);
      box.title = locked ? box.dataset.unlockLabel : box.dataset.lockLabel;
      box.setAttribute("aria-label", box.title);
      box.setAttribute("aria-pressed", String(!locked));
    }
  };

  const lock = () => {
    locked = true;
    fields.forEach((field) => { field.readOnly = true; });
    showFormatted(true);
    show();
    say(form.dataset.lockedHint);
  };

  // caret: where to put the caret; without one (padlock, Enter) the text
  // opens with the caret at its end.
  // The page must not move: focus without scrolling, put back any scroll
  // the swap to plain text caused, then (after a double-click at pointerY)
  // scroll so the caret's line sits where the user clicked.
  const unlock = (field = fields[fields.length - 1], caret = null, pointerY = null) => {
    const scrollY = window.scrollY;
    locked = false;
    fields.forEach((f) => { f.readOnly = false; });
    showFormatted(false);
    show();
    say("");
    field.focus({ preventScroll: true });
    if (caret !== null) {
      field.setSelectionRange(caret, caret);
    } else if (field === fields[fields.length - 1]) {
      field.setSelectionRange(field.value.length, field.value.length);
    }
    window.scrollTo(window.scrollX, scrollY);
    if (pointerY !== null && caret !== null && field.tagName === "TEXTAREA") {
      const shift = caretClientY(field, caret) - pointerY;
      if (Math.abs(shift) > 2) window.scrollBy(0, shift);
    }
  };

  // The first click of a double-click puts the (invisible) caret of the
  // read-only field where the pointer was; the second click selects a word.
  // Remember the first so editing starts exactly there.
  const clickCaret = new Map();
  fields.forEach((field) => {
    field.addEventListener("click", (event) => {
      if (locked && event.detail === 1) clickCaret.set(field, field.selectionStart);
    });
    field.addEventListener("dblclick", (event) => {
      if (locked) unlock(field, clickCaret.get(field) ?? field.selectionEnd, event.clientY);
    });
    field.addEventListener("keydown", (event) => {
      if (locked && event.key === "Enter") {
        event.preventDefault();
        unlock(field);
      } else if (!locked && event.key === "Escape") {
        field.blur();
      }
    });
  });

  view?.addEventListener("dblclick", (event) => {
    if (!locked || event.target.closest("a, input")) return;
    unlock(description, sourceOffsetAt(event.clientX, event.clientY), event.clientY);
  });

  // Maps a point in the formatted view to an offset in the Markdown text:
  // the clicked block's data-sourcepos gives where it starts in the text,
  // then the visible characters before the point are matched one by one in
  // the source, skipping Markdown syntax (*, _, #, [, ](url), "- [ ]", ...).
  const sourceOffsetAt = (x, y) => {
    let node;
    let offset;
    if (document.caretPositionFromPoint) {
      const position = document.caretPositionFromPoint(x, y);
      if (!position) return null;
      ({ offsetNode: node, offset } = position);
    } else if (document.caretRangeFromPoint) {
      const range = document.caretRangeFromPoint(x, y);
      if (!range) return null;
      ({ startContainer: node, startOffset: offset } = range);
    } else {
      return null;
    }
    const block = (node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement)?.closest("[data-sourcepos]");
    if (!block || !view.contains(block)) return null;

    const source = description.value;
    const lineStarts = [0];
    for (let i = 0; i < source.length; i += 1) if (source[i] === "\n") lineStarts.push(i + 1);
    const at = (line, column) => Math.min(source.length, (lineStarts[line - 1] ?? source.length) + column - 1);
    const [[startLine, startColumn], [endLine, endColumn]] =
      block.dataset.sourcepos.split("-").map((point) => point.split(":").map(Number));
    const start = at(startLine, startColumn);
    const end = at(endLine, endColumn) + 1;

    // Link addresses "](...)" are not visible text; never match inside them.
    const hidden = new Set();
    for (const match of source.slice(start, end).matchAll(/\]\([^)\n]*\)/g)) {
      for (let i = 0; i < match[0].length; i += 1) hidden.add(start + match.index + i);
    }

    const before = document.createRange();
    before.selectNodeContents(block);
    before.setEnd(node, offset);
    let caret = start;
    for (const character of before.toString()) {
      if (/\s/.test(character)) continue;
      let found = source.indexOf(character, caret);
      while (found !== -1 && hidden.has(found)) found = source.indexOf(character, found + 1);
      if (found === -1 || found >= end) break;
      caret = found + 1;
    }
    // A click just after a space lands after it, not before it.
    if (/\s$/.test(before.toString()) && source[caret] === " ") caret += 1;
    return caret;
  };
  view?.addEventListener("change", (event) => {
    if (event.target.matches("input[type=checkbox][data-task-line]")) toggleTask(event.target);
  });

  // Lock again once focus leaves both fields (after the blur save).
  form.addEventListener("focusout", (event) => {
    if (locked || fields.includes(event.relatedTarget)) return;
    save();
    lock();
  });

  // Keep focus in the field when the box is pressed, so the box (not the
  // focusout above) decides; Safari does not focus buttons on click.
  box?.addEventListener("mousedown", (event) => event.preventDefault());
  box?.addEventListener("click", () => {
    if (locked) {
      unlock();
    } else {
      save();
      lock();
    }
  });

  lock();
}

// The sort button next to the note count cycles the board order. Cards are
// reordered in place and glide to their new spot (FLIP: measure, move,
// animate the difference). The animation is kept light: transform only,
// about 0.3 s, only for cards on screen, none with reduced motion.
function setUpSort(button) {
  const board = document.querySelector(".board");
  if (!board) return;
  const sorts = JSON.parse(button.dataset.sorts);
  const keys = Object.keys(sorts);
  const label = button.querySelector("[data-sort-label]");
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  const compare = (sort) => {
    const [field, direction] = sort.split("_");
    const sign = direction === "asc" ? 1 : -1;
    return (a, b) =>
      sign * (Number(a.dataset[field]) - Number(b.dataset[field]) || Number(a.dataset.id) - Number(b.dataset.id));
  };

  const onScreen = (rect) => rect.bottom > 0 && rect.top < window.innerHeight;

  const reorder = (sort) => {
    const cards = [...board.querySelectorAll("[data-card]")];
    const before = new Map(cards.map((card) => [card, card.getBoundingClientRect()]));
    // Cards keep their place after the "new note" tile and before the empty text.
    const anchor = cards[0]?.previousElementSibling;
    const sorted = [...cards].sort(compare(sort));
    if (anchor) anchor.after(...sorted);
    else board.prepend(...sorted);
    if (reduceMotion.matches) return;

    sorted.forEach((card) => {
      const first = before.get(card);
      const last = card.getBoundingClientRect();
      if (!onScreen(first) && !onScreen(last)) return;
      // Under the text size zoom, rectangles are zoomed but translate is not.
      const zoom = card.currentCSSZoom || 1;
      const dx = (first.left - last.left) / zoom;
      const dy = (first.top - last.top) / zoom;
      if (!dx && !dy) return;
      card.animate([{ transform: `translate(${dx}px, ${dy}px)` }, { transform: "none" }],
                   { duration: 300, easing: "cubic-bezier(0.2, 0.7, 0.2, 1)" });
    });
  };

  button.addEventListener("click", (event) => {
    event.preventDefault();
    const sort = keys[(keys.indexOf(button.dataset.sort) + 1) % keys.length];
    reorder(sort);
    document.cookie = `sort=${sort}; path=/; max-age=31536000; samesite=lax`;
    button.dataset.sort = sort;
    label.textContent = sorts[sort];
    button.title = button.dataset.titleTemplate.replace("%{order}", sorts[sort]);
    const next = new URL(button.href);
    next.searchParams.set("sort", keys[(keys.indexOf(sort) + 1) % keys.length]);
    button.href = next;
  });
}

// Attachment preview: one <dialog> per page, filled from the clicked
// [data-preview-item] link. Arrow keys move between files; Escape closes.
function setUpPreview(dialog) {
  const items = [...document.querySelectorAll("[data-preview-item]")];
  if (items.length === 0) return;

  const media = dialog.querySelector("[data-preview-media]");
  const caption = dialog.querySelector("[data-preview-caption]");
  const meta = dialog.querySelector("[data-preview-meta]");
  const count = dialog.querySelector("[data-preview-count]");
  const download = dialog.querySelector("[data-preview-download]");
  const navButtons = dialog.querySelectorAll("[data-preview-prev], [data-preview-next]");
  let index = 0;

  const message = (text) => {
    const p = document.createElement("p");
    p.className = "preview__none";
    p.textContent = text;
    return p;
  };

  const render = (kind, url, name) => {
    switch (kind) {
      case "image": {
        const img = document.createElement("img");
        img.src = url;
        img.alt = name;
        return img;
      }
      case "pdf": {
        const frame = document.createElement("iframe");
        frame.src = url;
        frame.title = name;
        return frame;
      }
      case "video":
      case "audio": {
        const player = document.createElement(kind);
        player.src = url;
        player.controls = true;
        player.preload = "metadata";
        return player;
      }
      case "text": {
        const pre = document.createElement("pre");
        fetch(url, { credentials: "same-origin" })
          .then((response) => (response.ok ? response.text() : Promise.reject(response.status)))
          .then((text) => { pre.textContent = text; })
          .catch(() => pre.replaceWith(message(dialog.dataset.loadError)));
        return pre;
      }
      default:
        return message(dialog.dataset.noPreview);
    }
  };

  const show = (i) => {
    index = (i + items.length) % items.length;
    const item = items[index];
    const { previewKind, previewUrl, filename, details } = item.dataset;
    media.replaceChildren(render(previewKind, previewUrl, filename));
    caption.textContent = filename;
    meta.textContent = details;
    count.textContent = items.length > 1 ? `${index + 1} / ${items.length}` : "";
    download.href = item.href;
    navButtons.forEach((button) => { button.hidden = items.length < 2; });
  };

  items.forEach((item, i) => {
    item.addEventListener("click", (event) => {
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      show(i);
      dialog.showModal();
    });
  });

  dialog.querySelector("[data-preview-close]").addEventListener("click", () => dialog.close());
  dialog.querySelector("[data-preview-prev]").addEventListener("click", () => show(index - 1));
  dialog.querySelector("[data-preview-next]").addEventListener("click", () => show(index + 1));
  // A click on the backdrop lands on the dialog element itself.
  dialog.addEventListener("click", (event) => { if (event.target === dialog) dialog.close(); });
  dialog.addEventListener("keydown", (event) => {
    if (event.target.closest("video, audio")) return;
    if (event.key === "ArrowLeft") show(index - 1);
    if (event.key === "ArrowRight") show(index + 1);
  });
  // Emptying the media stops playback and frees large images.
  dialog.addEventListener("close", () => media.replaceChildren());
}

// Forms with data-confirm (delete buttons) ask first in a dialog that says
// what will happen; data-confirm-title and data-confirm-button fill it in.
// Without the dialog the browser's own confirm is used.
function setUpConfirm(dialog) {
  let pending = null;

  document.querySelectorAll("form[data-confirm]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      if (form.dataset.confirmed === "true") return;
      event.preventDefault();
      if (!dialog) {
        if (window.confirm(form.dataset.confirm)) submitConfirmed(form);
        return;
      }
      pending = form;
      dialog.querySelector("[data-confirm-title]").textContent = form.dataset.confirmTitle || dialog.dataset.defaultTitle;
      dialog.querySelector("[data-confirm-body]").textContent = form.dataset.confirm;
      dialog.querySelector("[data-confirm-ok]").textContent = form.dataset.confirmButton || dialog.dataset.defaultButton;
      dialog.returnValue = "";
      dialog.showModal();
      dialog.querySelector("[data-confirm-cancel]").focus();
    });
  });

  if (!dialog) return;
  // Escape and the backdrop cancel; only the destructive button confirms.
  dialog.addEventListener("click", (event) => { if (event.target === dialog) dialog.close(); });
  dialog.addEventListener("close", () => {
    if (dialog.returnValue === "confirm" && pending) submitConfirmed(pending);
    pending = null;
  });
}

function submitConfirmed(form) {
  form.dataset.confirmed = "true";
  form.requestSubmit();
}

// Files dragged onto the note window are attached with the upload form, using
// whatever is typed in its comment field.
function setUpDropUpload(form) {
  const zone = form.closest(".note-window") || form;
  const input = form.querySelector("input[type=file]");
  let depth = 0;

  const hasFiles = (event) => [...(event.dataTransfer?.types || [])].includes("Files");
  const setDragging = (on) => {
    zone.classList.toggle("is-dragging", on);
    if (on) zone.dataset.dropText = form.dataset.dropText;
  };

  zone.addEventListener("dragenter", (event) => {
    if (!hasFiles(event)) return;
    event.preventDefault();
    depth += 1;
    setDragging(true);
  });
  zone.addEventListener("dragover", (event) => {
    if (!hasFiles(event)) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "copy";
  });
  zone.addEventListener("dragleave", () => {
    depth = Math.max(0, depth - 1);
    if (depth === 0) setDragging(false);
  });
  zone.addEventListener("drop", (event) => {
    if (!hasFiles(event)) return;
    event.preventDefault();
    depth = 0;
    setDragging(false);
    if (event.dataTransfer.files.length === 0) return;
    input.files = event.dataTransfer.files;
    zone.classList.add("is-uploading");
    zone.dataset.dropText = form.dataset.uploadingText;
    form.requestSubmit();
  });

  // A file dropped next to the note must not make the browser open it instead.
  window.addEventListener("dragover", (event) => { if (hasFiles(event)) event.preventDefault(); }, { signal: pageSignal });
  window.addEventListener("drop", (event) => { if (hasFiles(event)) event.preventDefault(); }, { signal: pageSignal });
}

// The wide box in a note's title strip: the window widens or narrows at once
// (a short max-width transition) and the choice is saved in the background.
function setUpWideToggle(form) {
  const windowEl = form.closest(".note-window");
  const button = form.querySelector("button[name='note[wide]']");
  if (!windowEl || !button) return;

  const regrow = () => windowEl.querySelectorAll("[data-autogrow]").forEach((area) => area.dispatchEvent(new Event("autogrow")));
  windowEl.addEventListener("transitionend", (event) => { if (event.propertyName === "max-width") regrow(); });

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const wide = button.value === "1";
    windowEl.classList.toggle("note-window--wide", wide);
    button.value = wide ? "0" : "1";
    button.setAttribute("aria-pressed", String(wide));
    button.title = wide ? form.dataset.wideLabel : form.dataset.narrowLabel;
    button.setAttribute("aria-label", button.title);
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) regrow();

    const body = new FormData(form);
    body.set("note[wide]", wide ? "1" : "0");
    const token = document.querySelector("meta[name=csrf-token]");
    if (token) body.set("authenticity_token", token.content);
    turboFetch(form.action, { method: "POST", body, headers: { Accept: "application/json" }, credentials: "same-origin" });
  });
}

// The colour menu of a new note changes the paper right away; the colour is
// saved with the note. The dice picks one of the other colours.
function setUpColorChoices() {
  const choices = [...document.querySelectorAll("[data-color-choice]")];
  choices.forEach((input) => {
    input.addEventListener("change", () => {
      const sticky = input.closest("[data-sticky]");
      if (!sticky) return;
      sticky.className = sticky.className.replace(/\bsticky--\w+/, `sticky--${input.value}`);
    });
  });

  document.querySelectorAll("[data-color-random]").forEach((button) => {
    button.addEventListener("click", () => {
      const others = choices.filter((input) => !input.checked);
      const pick = others[Math.floor(Math.random() * others.length)];
      if (!pick) return;
      pick.checked = true;
      pick.dispatchEvent(new Event("change"));
    });
  });
}

// The time capsule: versions stacked into the distance, the selected one in
// front. Arrow keys, the arrow buttons and the timeline move through time;
// links keep working without JavaScript.
function setUpCapsule(capsule) {
  const cards = [...capsule.querySelectorAll("[data-capsule-card]")];
  const ticks = [...capsule.querySelectorAll("[data-capsule-jump]")];
  const position = capsule.querySelector("[data-capsule-position]");
  let selected = Number(capsule.dataset.selected);

  const show = (index, { focusTick = false } = {}) => {
    selected = Math.max(0, Math.min(cards.length - 1, index));
    cards.forEach((card, i) => {
      const depth = selected - i;
      card.style.setProperty("--depth", depth);
      card.classList.toggle("is-future", depth < 0);
      card.classList.toggle("is-far", depth > 7);
      card.setAttribute("aria-hidden", i !== selected);
    });
    ticks.forEach((tick, i) => {
      if (i === selected) tick.setAttribute("aria-current", "true");
      else tick.removeAttribute("aria-current");
    });
    const tick = ticks[selected];
    if (tick) {
      tick.scrollIntoView({ block: "nearest" });
      if (focusTick) tick.focus();
    }
    position.textContent = `${selected + 1} / ${cards.length}`;
    const id = cards[selected].id.replace("version-", "");
    history.replaceState(history.state, "", `${capsule.dataset.url}?v=${id}`);
  };

  ticks.forEach((tick) => {
    tick.addEventListener("click", (event) => {
      event.preventDefault();
      show(Number(tick.dataset.capsuleJump));
    });
  });
  capsule.querySelectorAll("[data-capsule-step]").forEach((button) => {
    button.addEventListener("click", (event) => {
      event.preventDefault();
      show(selected + Number(button.dataset.capsuleStep));
    });
  });
  // A click on a card behind the front one travels back to it.
  cards.forEach((card, i) => {
    card.addEventListener("click", () => { if (i !== selected) show(i); });
  });
  document.addEventListener("keydown", (event) => {
    if (event.target.closest("input, textarea, select") || document.querySelector("dialog[open]")) return;
    if (event.key === "ArrowUp") { event.preventDefault(); show(selected - 1); }
    if (event.key === "ArrowDown") { event.preventDefault(); show(selected + 1); }
  }, { signal: pageSignal });
  // Mouse wheel over the stack moves through time, one step per notch.
  let wheelLock = false;
  capsule.querySelector("[data-capsule-stack]").addEventListener("wheel", (event) => {
    if (event.target.closest(".capsule__body") && event.target.closest("[data-capsule-card]") === cards[selected]) return;
    event.preventDefault();
    if (wheelLock || Math.abs(event.deltaY) < 4) return;
    wheelLock = true;
    setTimeout(() => { wheelLock = false; }, 250);
    show(selected + (event.deltaY < 0 ? -1 : 1));
  }, { passive: false });

  const changes = capsule.querySelector("[data-capsule-changes]");
  changes.addEventListener("change", () => capsule.classList.toggle("capsule--plain", !changes.checked));

  show(selected);
}

// Live updates (specs/live-updates.md). A note's page and its share page
// subscribe to a stream (turbo_stream_from) on which the server sends only
// "refresh" when the note changes; Turbo then fetches the page again and
// keeps the scroll position. A refresh that would throw away work in
// progress waits until the page is idle: a note being edited or saved, a
// typed field or chosen file, an open dialog or menu.
let pendingRefresh = null;
let refreshScroll = null;

function fieldChanged(field) {
  if (field.type === "file") return field.files.length > 0;
  if (field.type === "checkbox" || field.type === "radio") return field.checked !== field.defaultChecked;
  return field.value !== field.defaultValue;
}

function pageIsBusy() {
  if (busyChecks.some((check) => check())) return true;
  if (document.querySelector("dialog[open], details[open]")) return true;
  const active = document.activeElement;
  if (active?.matches("textarea, select, input:not([type=checkbox], [type=radio], [type=button], [type=submit])") &&
      !active.readOnly) return true;
  // The note's own fields are covered by its busy check (they differ from
  // their first value after every autosave).
  return [...document.querySelectorAll("input, textarea, select")]
    .some((field) => !field.closest("form[data-note-form]") && fieldChanged(field));
}

function runPendingRefresh() {
  const refresh = pendingRefresh;
  pendingRefresh = null;
  // The new body starts with short text areas until autoGrow sizes them,
  // which can pull a long page's scroll up; setUpPage puts it back.
  refreshScroll = { url: location.href, y: window.scrollY, at: Date.now() };
  refresh();
}

function setUpLiveRefresh() {
  pendingRefresh = null;
  if (refreshScroll && refreshScroll.url === location.href && Date.now() - refreshScroll.at < 10000) {
    const { y } = refreshScroll;
    const restore = () => window.scrollTo(window.scrollX, y);
    restore();
    document.fonts?.ready.then(restore);
  }
  refreshScroll = null;

  const interval = setInterval(() => {
    if (pendingRefresh && !pageIsBusy()) runPendingRefresh();
  }, 1000);
  pageSignal.addEventListener("abort", () => clearInterval(interval));
}

document.addEventListener("turbo:before-stream-render", (event) => {
  if (event.detail.newStream.getAttribute("action") !== "refresh") return;
  const render = event.detail.render;
  event.detail.render = async (stream) => {
    pendingRefresh = () => render(stream);
    if (!pageIsBusy()) {
      runPendingRefresh();
    } else if (document.querySelector("form[data-note-form]:not(.is-locked)")) {
      document.querySelectorAll("[data-remote-notice]").forEach((notice) => { notice.hidden = false; });
    }
  };
});

// Close an open filter menu when clicking elsewhere (once, for all pages).
document.addEventListener("click", (event) => {
  document.querySelectorAll("[data-filter][open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.open = false;
  });
});

function setUpPage() {
  pageAbort?.abort();
  pageAbort = new AbortController();
  pageSignal = pageAbort.signal;
  busyChecks = [];

  document.querySelectorAll("[data-autogrow]").forEach(autoGrow);
  document.querySelectorAll("[data-copy-note]").forEach(setUpCopyNote);
  document.querySelectorAll("form[data-note-form]").forEach(setUpNoteForm);

  setUpConfirm(document.querySelector("[data-confirm-dialog]"));

  document.querySelectorAll("[data-preview-dialog]").forEach(setUpPreview);
  setUpColorChoices();
  document.querySelectorAll("form[data-wide-toggle]").forEach(setUpWideToggle);
  document.querySelectorAll("[data-sort-button]").forEach(setUpSort);
  document.querySelectorAll("[data-capsule]").forEach(setUpCapsule);
  document.querySelectorAll("form[data-drop-upload]").forEach(setUpDropUpload);
  setUpLiveRefresh();

  // Theme and text size apply at once; the cookie keeps them for the next page.
  document.querySelectorAll("form[data-preference]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      const button = event.submitter;
      if (!button || !button.name) return;
      event.preventDefault();
      document.cookie = `${button.name}=${button.value}; path=/; max-age=31536000; samesite=lax`;
      document.documentElement.dataset[button.name] = button.value;
      if (button.name === "scale") {
        form.querySelectorAll("button[name=scale]").forEach((option) => {
          option.setAttribute("aria-pressed", option === button);
        });
      }
    });
  });

  // Picking a colour in the filter searches right away.
  document.querySelectorAll("[data-filter-choice]").forEach((input) => {
    input.addEventListener("change", () => input.form.requestSubmit());
  });

  // Clearing the search field (the field's own x button) shows all notes again.
  document.querySelectorAll("[data-search-form] input[type=search]").forEach((field) => {
    field.addEventListener("search", () => { if (field.value === "") field.form.requestSubmit(); });
  });

  document.querySelectorAll("[data-copy]").forEach((button) => {
    button.addEventListener("click", async () => {
      const field = document.querySelector(button.dataset.copy);
      const label = button.textContent;
      try {
        await navigator.clipboard.writeText(field.value);
      } catch {
        field.select();
        document.execCommand("copy");
      }
      button.textContent = button.dataset.copied;
      setTimeout(() => { button.textContent = label; }, 1500);
    });
  });

  // Notices fade out after a few seconds (not while hovered or focused);
  // alerts stay until closed.
  document.querySelectorAll("[data-flash]").forEach((flash) => {
    const dismiss = () => {
      flash.classList.add("is-leaving");
      setTimeout(() => flash.remove(), 400);
    };
    const close = flash.querySelector("[data-dismiss]");
    if (close) close.addEventListener("click", dismiss);
    if (flash.dataset.flashKind !== "notice") return;
    let timer = setTimeout(dismiss, 6000);
    const pause = () => clearTimeout(timer);
    const resume = () => { timer = setTimeout(dismiss, 3000); };
    flash.addEventListener("mouseenter", pause);
    flash.addEventListener("mouseleave", resume);
    flash.addEventListener("focusin", pause);
    flash.addEventListener("focusout", resume);
  });
}

// Turbo fires turbo:load after the first page and after every visit. If
// Turbo did not load (old browser, blocked module), set up the page once.
document.addEventListener("turbo:load", setUpPage);
document.addEventListener("DOMContentLoaded", () => {
  if (!window.Turbo) setUpPage();
});
