# QuickClick

An iPhone app that moves the Friends of Figma talk slides with the volume buttons.
It opens the talk's phone remote page and presses its Next and Previous buttons for you.

- Volume up: next. Volume down: previous.
- A short tap in your hand means the press went through. A triple buzz means it did not.
- Pocket mode: a black screen that ignores taps. Hold for one second to exit.
- The phone must stay unlocked with the app open. The app stops the phone locking itself.

## Companion to the talk deck

This is the companion clicker for the Friends of Figma talk deck: https://github.com/bookwormsuf/friends-of-figma-talk

It only works with the deployed deck at friends-of-figma-talk.vercel.app. The host is hard-coded in `Sources/ClickerApp.swift`.

To build it yourself you need your own Apple team ID and bundle ID. They are set in `project.yml` (`DEVELOPMENT_TEAM`, `PRODUCT_BUNDLE_IDENTIFIER`), in `QuickClick.xcodeproj/project.pbxproj` and, for the team ID, in `ExportOptions.plist`.

## Install on your phone

1. Open `QuickClick.xcodeproj` in Xcode.
2. Click the QuickClick target, then Signing & Capabilities, and pick your team.
3. Plug in the phone, choose it at the top, press Run.

`project.yml` is the source for the Xcode project. After changing it, run `xcodegen generate`.

## Pair

On the laptop press Phone, then New code, then scan it in the app.
New code matters if you paired in Safari before: the laptop only obeys the first phone it met.

## Not yet checked on a real phone

- That the volume resets after each press (the simulator has no volume buttons).
- Pocket mode in an actual pocket.

## Licence

MIT. See `LICENSE`.
