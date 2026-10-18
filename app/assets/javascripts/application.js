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

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-autogrow]").forEach(autoGrow);
  document.querySelectorAll("form[data-note-form]").forEach(setUpNoteForm);

  // Forms rendered with data-confirm (delete buttons) ask before submitting.
  document.querySelectorAll("form[data-confirm]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      if (!window.confirm(form.dataset.confirm)) event.preventDefault();
    });
  });

  document.querySelectorAll("[data-flash]").forEach((flash) => {
    const close = flash.querySelector("[data-dismiss]");
    if (close) close.addEventListener("click", () => flash.remove());
  });
});
