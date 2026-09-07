# TopDownNotifications16

Native iOS 16 notifications, positioned from the top of the notification area so the list grows downward.

For rootless iOS 16 jailbreaks, including Dopamine. Install the DEB from Releases and respring. Enabled automatically; uninstall and respring to restore the stock layout.

## Scope

The `NCNotificationListView` layout direction getter and setter select top-down layout. An optional `listMinY` offset moves the notification area as a whole. At the default 0 offset, the original position is returned unchanged. The native engine calculates all positions. Notification cards, data ordering, grouping, display mode, animations, gestures, clear actions and sounds are not replaced or configured by this tweak. Count mode continues to show a count until expanded.

The native notification area below the clock/widgets is retained. The default remains below the clock. Settings → TopDownNotifications16 provides a vertical position slider, 5-point up/down buttons, reset, respring and a GitHub link. Respring to apply position changes. Requires PreferenceLoader.

The direction override applies to every instance of the native notification list, including nested group lists. The intended result is downward growth for both the outer list and expanded groups. Collapsed groups retain their native overlapping-card appearance. Group layout still needs confirmation on the device.

## Validation status

The user reports that the original default position works well. Version 1.1.0 preserves it and adds position preferences. Compilation and package validation do not establish runtime compatibility. The layout and interactions must be checked on a jailbroken iOS 16 device; no physical-device test has been performed by the build environment.

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
