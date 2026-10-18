// Page behaviour for g0No. Plain JavaScript, no framework.

function autoGrow(textarea) {
  const grow = () => {
    textarea.style.height = "auto";
    textarea.style.height = `${textarea.scrollHeight}px`;
  };
  textarea.addEventListener("input", grow);
  grow();
}

// The save/cancel bar of an existing note stays hidden until the title or
// description changes, like editing a sticky in place.
function setUpNoteForm(form) {
  const actions = form.querySelector("[data-note-actions]");
  const title = form.querySelector(".note-title");
  const show = () => { if (actions) actions.hidden = false; };

  form.querySelectorAll(".note-title, .note-description").forEach((field) => {
    field.addEventListener("input", show);
  });

  if (title) {
    title.addEventListener("input", () => {
      document.title = title.value ? `g0No - ${title.value}` : "g0No";
    });
  }

  const reset = form.querySelector("[data-note-reset]");
  if (reset) {
    form.addEventListener("reset", () => {
      // Let the browser restore the values first, then resize and hide.
      setTimeout(() => {
        form.querySelectorAll("[data-autogrow]").forEach((el) => el.dispatchEvent(new Event("input")));
        if (actions) actions.hidden = true;
      });
    });
  }
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
  document.querySelectorAll("form[data-note-form]").forEach(setUpNoteForm);

  setUpConfirm(document.querySelector("[data-confirm-dialog]"));

  document.querySelectorAll("[data-preview-dialog]").forEach(setUpPreview);
  setUpColorChoices();
  document.querySelectorAll("[data-capsule]").forEach(setUpCapsule);
  document.querySelectorAll("form[data-drop-upload]").forEach(setUpDropUpload);

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
