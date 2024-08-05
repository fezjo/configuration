# Floorp

- Login to Firefox account
- Customize toolbar
- Bookmark bar always hide
- History: View by last visited
- Find: Highlight All
- Change default search engine
  - go to `startpage.com`
  - open URL bar
  - on the bottom, select icon to add search engine
  - go to settings
  - change default search engine to `startpage.com`
  - add `@g` shortcut for `google.com`

## Settings

- General
  - Browsing
    - Always show scrollbars
- Design
  - Firefox Photon - Lepton UI
  - Collapse Tree Style Tab
  - Optimise browser for Vertical Tab Bar
- Workspaces
  - Close workspaces popup when selecting a Workspace
  - Manage Workspace on Browser Manager Sidebar
- Search
  - Default Search Engine
- Privacy and Security
  - Enahnced Tracking Protection: _Strict_
  - Send websites a "Do Not Track" signal that you don't want to be tracked: _Always_
  - Ask to save logins and passwords for websites: _OFF_
  - HTTPS-Only Mode: _Enable HTTPS-Only Mode in all windows_

# Extensions

## UBlock Origin

- Filter list ([inspiration](https://github.com/yokoffing/filterlists#guidelines))
  <details>
  <summary>Backup</summary>

  ```json
  {
    "timeStamp": 1711494731403,
    "version": "1.56.0",
    "userSettings": {
      "externalLists": "https://gitlab.com/magnolia1234/bypass-paywalls-clean-filters/-/raw/main/bpc-paywall-filter.txt\nhttps://raw.githubusercontent.com/DandelionSprout/adfilt/master/BrowseWebsitesWithoutLoggingIn.txt\nhttps://raw.githubusercontent.com/DandelionSprout/adfilt/master/Dandelion Sprout's Anti-Malware List.txt\nhttps://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt\nhttps://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.plus.mini.txt\nhttps://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/spam-tlds-ublock.txt\nhttps://raw.githubusercontent.com/iam-py-test/my_filters_001/main/antimalware.txt\nhttps://raw.githubusercontent.com/liamengland1/miscfilters/master/antipaywall.txt\nhttps://raw.githubusercontent.com/yokoffing/filterlists/main/annoyance_list.txt\nhttps://raw.githubusercontent.com/yokoffing/filterlists/main/privacy_essentials.txt",
      "importedLists": [
        "https://gitlab.com/magnolia1234/bypass-paywalls-clean-filters/-/raw/main/bpc-paywall-filter.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/BrowseWebsitesWithoutLoggingIn.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Dandelion Sprout's Anti-Malware List.txt",
        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt",
        "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.plus.mini.txt",
        "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/spam-tlds-ublock.txt",
        "https://raw.githubusercontent.com/iam-py-test/my_filters_001/main/antimalware.txt",
        "https://raw.githubusercontent.com/liamengland1/miscfilters/master/antipaywall.txt",
        "https://raw.githubusercontent.com/yokoffing/filterlists/main/annoyance_list.txt",
        "https://raw.githubusercontent.com/yokoffing/filterlists/main/privacy_essentials.txt"
      ]
    },
    "selectedFilterLists": [
      "user-filters",
      "ublock-filters",
      "ublock-badware",
      "ublock-privacy",
      "ublock-quick-fixes",
      "ublock-unbreak",
      "easylist",
      "adguard-spyware",
      "block-lan",
      "easyprivacy",
      "urlhaus-1",
      "plowe-0",
      "adguard-mobile-app-banners",
      "adguard-other-annoyances",
      "adguard-popup-overlays",
      "adguard-social",
      "adguard-widgets",
      "adguard-cookies",
      "ublock-cookies-adguard",
      "easylist-chat",
      "easylist-newsletters",
      "easylist-notifications",
      "easylist-annoyances",
      "fanboy-social",
      "fanboy-cookiemonster",
      "ublock-cookies-easylist",
      "ublock-annoyances",
      "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt",
      "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/BrowseWebsitesWithoutLoggingIn.txt",
      "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Dandelion Sprout's Anti-Malware List.txt",
      "https://raw.githubusercontent.com/yokoffing/filterlists/main/privacy_essentials.txt",
      "https://raw.githubusercontent.com/yokoffing/filterlists/main/annoyance_list.txt",
      "https://raw.githubusercontent.com/liamengland1/miscfilters/master/antipaywall.txt",
      "https://gitlab.com/magnolia1234/bypass-paywalls-clean-filters/-/raw/main/bpc-paywall-filter.txt",
      "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.plus.mini.txt",
      "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/spam-tlds-ublock.txt",
      "https://raw.githubusercontent.com/iam-py-test/my_filters_001/main/antimalware.txt"
    ],
    "hiddenSettings": {},
    "whitelist": [
      "about-scheme",
      "chrome-extension-scheme",
      "chrome-scheme",
      "edge-scheme",
      "moz-extension-scheme",
      "opera-scheme",
      "vivaldi-scheme",
      "wyciwyg-scheme"
    ],
    "dynamicFilteringString": "behind-the-scene * * noop\nbehind-the-scene * inline-script noop\nbehind-the-scene * 1p-script noop\nbehind-the-scene * 3p-script noop\nbehind-the-scene * 3p-frame noop\nbehind-the-scene * image noop\nbehind-the-scene * 3p noop",
    "urlFilteringString": "",
    "hostnameSwitchesString": "no-large-media: behind-the-scene false\nno-csp-reports: * true",
    "userFilters": ""
  }
  ```

  </details>

## Tab Session Manager

- Export/Import session
- Switch filter to "User saved"
- Remove `Ctrl+Shift+L` shortcut

## Bitwarden

- Settings
  - Autofill
    - Show menu when icon selected
  - Vault timeout: _5 minutes_
  - Unlock with pin
    - NO lock with master password on browser restart
  - Options
    - Clear clipboard: _20 seconds_

## Enhancer for Youtube

- Export/Import

## Vimium C

- Disable `F` on Youtube
- Disable on MonkeyType

## SponsorBlock

- Minimum duration (seconds): _1_
