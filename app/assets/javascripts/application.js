// Page behaviour for g0No. Plain JavaScript, no framework.

// Text areas grow with their text instead of scrolling. scrollHeight leaves
// out the border, which with border-box sizing would leave the box a pixel
// short and bring back the scroll bar. Overflow is hidden on both axes: the
// text always wraps, and with the Big / Extra big zoom rounding can make the
// content a fraction wider than the box. Without JavaScript the field keeps
// its normal scroll bar, so no text is hidden.
function autoGrow(textarea) {
  textarea.style.overflow = "hidden";
  const grow = () => {
    textarea.style.height = "auto";
    const border = textarea.offsetHeight - textarea.clientHeight;
    textarea.style.height = `${textarea.scrollHeight + border}px`;
  };
  textarea.addEventListener("input", grow);
  // Sent when a hidden text area is shown again (Markdown notes).
  textarea.addEventListener("autogrow", grow);
  window.addEventListener("resize", grow);
  document.fonts?.ready.then(grow);
  // The text size menu changes data-scale on <html>; the wrap changes with it.
  new MutationObserver(grow).observe(document.documentElement, { attributes: true, attributeFilter: ["data-scale"] });
  grow();
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
  const formData = () => {
    const body = new FormData(form);
    const token = document.querySelector("meta[name=csrf-token]");
    if (token) body.set("authenticity_token", token.content);
    return body;
  };

  // A created note continues as an update of that note.
  const becomeExisting = (url) => {
    form.action = url;
    const method = document.createElement("input");
    Object.assign(method, { type: "hidden", name: "_method", value: "patch" });
    form.prepend(method);
    history.replaceState(null, "", url);
  };

  const save = async () => {
    clearTimeout(timer);
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
    const body = formData();
    say(form.dataset.saving);
    try {
      const response = await fetch(form.action, {
        method: "POST",
        body,
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(data.error || response.statusText);
      saved = body;
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
    const body = formData();
    fetch(form.action, { method: "POST", body, keepalive: true, headers: { Accept: "application/json" }, credentials: "same-origin" });
    saved = body;
  };
  window.addEventListener("pagehide", flush);
  document.addEventListener("visibilitychange", () => { if (document.visibilityState === "hidden") flush(); });

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    save();
  });

  setUpNoteLock(form, { save, say });

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
  const unlock = (field = fields[fields.length - 1], caret = null) => {
    locked = false;
    fields.forEach((f) => { f.readOnly = false; });
    showFormatted(false);
    show();
    say("");
    field.focus();
    if (caret !== null) {
      field.setSelectionRange(caret, caret);
    } else if (field === fields[fields.length - 1]) {
      field.setSelectionRange(field.value.length, field.value.length);
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
    field.addEventListener("dblclick", () => {
      if (locked) unlock(field, clickCaret.get(field) ?? field.selectionEnd);
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
    unlock(description, sourceOffsetAt(event.clientX, event.clientY));
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
  window.addEventListener("dragover", (event) => { if (hasFiles(event)) event.preventDefault(); });
  window.addEventListener("drop", (event) => { if (hasFiles(event)) event.preventDefault(); });
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
    history.replaceState(null, "", `${capsule.dataset.url}?v=${id}`);
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
  });
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

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-autogrow]").forEach(autoGrow);
  document.querySelectorAll("[data-copy-note]").forEach(setUpCopyNote);
  document.querySelectorAll("form[data-note-form]").forEach(setUpNoteForm);

  setUpConfirm(document.querySelector("[data-confirm-dialog]"));

  document.querySelectorAll("[data-preview-dialog]").forEach(setUpPreview);
  setUpColorChoices();
  document.querySelectorAll("[data-sort-button]").forEach(setUpSort);
  document.querySelectorAll("[data-capsule]").forEach(setUpCapsule);
  document.querySelectorAll("form[data-drop-upload]").forEach(setUpDropUpload);

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

  // Picking a colour in the menu bar filter searches right away.
  document.querySelectorAll("[data-filter-choice]").forEach((input) => {
    input.addEventListener("change", () => input.form.requestSubmit());
  });

  // Close the filter menu when clicking elsewhere.
  document.addEventListener("click", (event) => {
    document.querySelectorAll("[data-filter][open]").forEach((menu) => {
      if (!menu.contains(event.target)) menu.open = false;
    });
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
});
