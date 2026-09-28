# TopDownNotifications16

iOS 14-15 style notifications for iOS 16. Notifications start at the top and stack downward, including groups.

## Features

| Feature | What it does |
|---|---|
| **Master Enabled switch** | Enables or disables the entire tweak. When disabled, none of the notification hooks or position hooks initialize. |
| **iOS 16 only** | Explicitly checks the OS major version and exits on anything other than iOS 16. |
| **SpringBoard only** | Injection is restricted to `com.apple.springboard`. |
| **Rootless Dopamine support** | Builds rootless for `iphoneos-arm64` with arm64 and arm64e binaries. |
| **Top-down notifications** | Forces `NCNotificationListView.layoutFromBottom = NO` so notifications begin at the top and grow downward. |
| **Prevents iOS reverting layout** | Any attempt to switch the list back to bottom-up layout is forced back to top-down. |
| **First notification position** | Provides an adjustable starting position for the first notification. |
| **Position slider** | Moves the first notification from **-100 pt up to +250 pt down**. |
| **±5 pt controls** | Includes Move Up 5 pt and Move Down 5 pt buttons for fine adjustment. |
| **Reset position** | Restores the first notification offset to the default 0 pt position. |
| **Notification groups** | Keeps Apple's native grouped-notification behaviour while groups expand downward. |
| **Notification Centre header fix** | Makes the `Notification Centre` + X history header follow the reveal progress instead of appearing immediately. |
| **Unlock header-flash fix** | Prevents the Notification Centre header from briefly flashing during lock/unlock transitions. |
| **iOS 15 side margins** | Changes notification-list horizontal insets from roughly 10 pt to 8 pt. |
| **Live Activity width compensation** | Widens hosted Live Activities by 4 pt so their edges continue to align after the notification margin change. |
| **iOS 15 internal padding** | Reduces notification-card internal spacing by roughly 4 pt per edge. |
| **More compact cards** | Uses the tighter iOS 15-style notification measurements rather than the taller iOS 16 layout. |
| **Vertically centred app icon** | Centres the notification app icon vertically on taller or multiline notifications. |
| **13 pt card corners** | Uses the tighter iOS 15-style 13 pt notification-card corner radius. |
| **Stack overlay corners** | Applies the same 13 pt radius to the dimming layer used by stacked notifications. |
| **Always-expanded List display** | Forces SpringBoard's effective iOS 16 notification display style to **List** while the tweak is enabled, preventing the global Stack/Count state from collapsing notifications into an `N+ Notifications` pile. The user's saved Display As preference is left unchanged. |
| **Respring button** | Uses rootless `sbreload`, with a SpringBoard restart fallback. |
| **Preference values clamped** | Rejects invalid/non-finite position values and keeps the offset within -100 to +250 pt. |
| **Runtime safety check** | Verifies the `layoutFromBottom` getter and setter exist with the expected BOOL signatures before activating the layout hooks. |
