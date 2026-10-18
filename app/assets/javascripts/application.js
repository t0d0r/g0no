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
// saved with the note.
function setUpColorChoices() {
  document.querySelectorAll("[data-color-choice]").forEach((input) => {
    input.addEventListener("change", () => {
      const sticky = input.closest("[data-sticky]");
      if (!sticky) return;
      sticky.className = sticky.className.replace(/\bsticky--\w+/, `sticky--${input.value}`);
    });
  });
}

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-autogrow]").forEach(autoGrow);
  document.querySelectorAll("form[data-note-form]").forEach(setUpNoteForm);

  setUpConfirm(document.querySelector("[data-confirm-dialog]"));

  document.querySelectorAll("[data-preview-dialog]").forEach(setUpPreview);
  setUpColorChoices();
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

  document.querySelectorAll("[data-flash]").forEach((flash) => {
    const close = flash.querySelector("[data-dismiss]");
    if (close) close.addEventListener("click", () => flash.remove());
  });
});
