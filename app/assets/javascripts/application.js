// Page behaviour for g0No. Plain JavaScript; replaces the jQuery, jQuery UI
// and Prototype code used before the Rails 8 migration.

let oldColor = "";
let buttonBarShown = false;

function showButtonBar(input) {
  const newColor = "red";
  oldColor = getComputedStyle(input).borderColor;
  const bar = document.querySelector("div#note_button_bar");
  if (bar && !buttonBarShown) {
    bar.style.display = "";
    buttonBarShown = true;
  }
  if (newColor !== oldColor) {
    input.style.borderColor = newColor;
  }
}

function hideButtonBar() {
  document.querySelectorAll("input#note_title, textarea#note_description").forEach((el) => {
    el.style.borderColor = oldColor;
  });
  const bar = document.querySelector("div#note_button_bar");
  if (bar) bar.style.display = "none";
  buttonBarShown = false;
}

// Shows a label inside its empty input and hides it while the input has focus
// or a value.
function labelOver(label, overClass) {
  const input = document.getElementById(label.htmlFor);
  if (!input) return;

  const hide = () => { label.style.textIndent = "-10000px"; };
  const show = () => { if (input.value === "") label.style.textIndent = "0"; };

  input.addEventListener("focus", hide);
  input.addEventListener("blur", show);
  label.classList.add(overClass);
  label.addEventListener("click", () => input.focus());
  if (input.value !== "") hide();
}

function autoGrow(textarea) {
  const grow = () => {
    textarea.style.height = "auto";
    textarea.style.height = `${textarea.scrollHeight}px`;
  };
  textarea.addEventListener("input", grow);
  grow();
}

function toggle(selector) {
  const el = document.querySelector(selector);
  if (el) el.style.display = el.style.display === "none" ? "" : "none";
}

document.addEventListener("DOMContentLoaded", () => {
  [
    "label.note_title",
    "label.note_description",
    "label.finance_date",
    "label.finance_amount",
    "label.finance_comment",
    "label.note_attachment_comment"
  ].forEach((selector) => {
    document.querySelectorAll(selector).forEach((label) => labelOver(label, "over"));
  });

  const title = document.querySelector("input#note_title");
  if (title) {
    title.addEventListener("keyup", () => {
      document.title = title.value;
      showButtonBar(title);
    });
  }

  const description = document.querySelector("textarea#note_description");
  if (description) {
    autoGrow(description);
    description.addEventListener("keyup", () => showButtonBar(description));
  }

  const reset = document.querySelector("#note_reset_button");
  if (reset) reset.addEventListener("click", hideButtonBar);

  const financeSwitch = document.querySelector("#finance_switch");
  if (financeSwitch) {
    financeSwitch.addEventListener("click", (event) => {
      event.preventDefault();
      toggle("#add_finance");
    });
  }

  const uploadSwitch = document.querySelector("#upload_file_switch");
  if (uploadSwitch) {
    uploadSwitch.addEventListener("click", (event) => {
      event.preventDefault();
      toggle("#upload_file_div");
    });
  }

  // Forms rendered with data-confirm (delete buttons) ask before submitting.
  document.querySelectorAll("form[data-confirm]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      if (!window.confirm(form.dataset.confirm)) event.preventDefault();
    });
  });
});
