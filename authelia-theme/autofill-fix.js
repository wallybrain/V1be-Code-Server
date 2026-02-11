// Bridge password manager autofill into React's synthetic event system.
// React overrides the native input value setter, so direct DOM changes
// (like 1Password fill) don't trigger state updates. This script
// detects filled values and dispatches proper events exactly once.
//
// IMPORTANT: Only runs on the login page. Skipped on TOTP registration
// and settings pages where autofill interferes with setup flows.
(function () {
  // Skip on TOTP registration/settings pages — autofill breaks these flows
  var path = window.location.hash || window.location.pathname;
  if (/one-time-password|totp|settings|register/i.test(path)) return;

  var nativeSetter = Object.getOwnPropertyDescriptor(
    HTMLInputElement.prototype,
    "value"
  ).set;

  // Track which values we've already synced to avoid duplicate submissions
  var synced = {};

  function syncInput(el) {
    // Only bridge username and password fields on the login page
    if (el.type !== "text" && el.type !== "password") return;
    var key = el.id || el.name || el.type;
    var val = el.value;
    if (!val || synced[key] === val) return;
    synced[key] = val;
    nativeSetter.call(el, val);
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
  }

  function poll() {
    // Re-check path in case of SPA navigation
    var curPath = window.location.hash || window.location.pathname;
    if (/one-time-password|totp|settings|register/i.test(curPath)) return;

    var fields = document.querySelectorAll(
      'input[type="text"], input[type="password"]'
    );
    fields.forEach(syncInput);
  }

  // Poll for autofill changes for 30 seconds (covers login screen)
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
