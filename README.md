# TopDownNotifications16

Native iOS 16 notifications, positioned from the top of the notification area so the list grows downward.

For rootless iOS 16 jailbreaks, including Dopamine. Install the DEB from Releases and respring. Enabled automatically; uninstall and respring to restore the stock layout.

## Scope

Only the `NCNotificationListView` layout direction getter and setter are hooked. The native engine calculates all positions. Notification cards, data ordering, grouping, display mode, animations, gestures, clear actions and sounds are not replaced or configured by this tweak. Count mode continues to show a count until expanded.

The native notification area below the clock/widgets is retained. This does not move notifications above the clock. No Settings panel or dependencies on preference libraries.

## Validation status

First device-test build. Compilation and package validation do not establish runtime compatibility. The layout and interactions must be checked on a jailbroken iOS 16 device; no physical-device test has been performed by the build environment.

Check one notification, multiple notifications, a grouped conversation, group expansion/collapse, scrolling a long list, swipe actions, clearing, media controls and lock/unlock. Apple still controls notification ordering and insertion animation paths. The hooks have runtime signature guards and do nothing on other iOS major versions.

## Build

Use Theos with the iOS 16.5 SDK:

```sh
make clean package FINALPACKAGE=1
```

The GitHub Actions workflow builds arm64 and arm64e, validates the rootless package and publishes the DEB.

## Technical references

- [Dodo's iOS 16 layout hooks](https://github.com/ginsudev/Dodo/blob/main/Dodo/Sources/Dodo/Hooks/NotificationsLayoutHooks.swift) document the native `layoutFromBottom` selector. This project does not adopt Dodo's collapsible-list override or its custom lock-screen layout.
- [Notification list runtime interface](https://github.com/MTACS/iOS-17-Runtime-Headers/blob/main/PrivateFrameworks/UserNotificationsUIKit.framework/NCNotificationListView.h) provides a later-version cross-check of the selector signatures; the installed iOS 16 runtime is checked before hooks are applied.
