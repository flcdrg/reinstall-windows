// Firefox profile defaults for me
user_pref("browser.urlbar.placeholderName", "DuckDuckGo");
user_pref("browser.urlbar.placeholderName.private", "DuckDuckGo");
user_pref("browser.download.useDownloadDir", false);

// We use Bitwarden to save signons
user_pref("signon.rememberSignons", false);

// Disable AI/ML features
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.menu", false); // Disable ML Chat in context menu
user_pref("browser.ml.enable", false);