{
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      FirefoxHome = {
        Stories = false;
        SponsoredPocket = false;
        SponsoredStories = false;
        TopSites = false;
        Highlights = false;
        Snippets = false;
      };

      SearchEngines = {
        Default = "DuckDuckGo";
      };

      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "normal_installed";
        };
      };

      Preferences = {
        "print.prefer_system_dialog" = true;
      };
    };
  };
}
