// Bridge password manager autofill into React's synthetic event system.
// React overrides the native input value setter, so direct DOM changes
// (like 1Password fill) don't trigger state updates. This script
// detects filled values and dispatches proper events exactly once.
(function () {
  var nativeSetter = Object.getOwnPropertyDescriptor(
    HTMLInputElement.prototype,
    "value"
  ).set;

  // Track which values we've already synced to avoid duplicate submissions
  var synced = {};

  function syncInput(el) {
    var key = el.id || el.name || el.type;
    var val = el.value;
    if (!val || synced[key] === val) return;
    synced[key] = val;
    nativeSetter.call(el, val);
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
  }

  function poll() {
    var fields = document.querySelectorAll(
      'input[type="text"], input[type="password"], input[type="tel"], input[type="number"]'
    );
    fields.forEach(syncInput);
  }

  // Poll for autofill changes for 30 seconds (covers login + TOTP screens)
  var interval = setInterval(poll, 500);
  setTimeout(function () {
    clearInterval(interval);
  }, 30000);

  // Re-poll on click/focus (covers manual 1Password popup fill)
  document.addEventListener("click", function () {
    setTimeout(poll, 300);
  });
  document.addEventListener("focusin", function () {
    setTimeout(poll, 300);
  });
})();
