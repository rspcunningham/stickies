# iOS App

The iOS client uses the same CloudKit private database as the macOS app:

- Container: `iCloud.dev.rspcunningham.stickies`
- Zone: `Stickies`
- Record type: `StickyNote`

Generate the Xcode project and build the simulator app:

```sh
./script/build_ios.sh
```

Build for a physical iOS device with automatic signing:

```sh
IOS_DESTINATION='generic/platform=iOS' ./script/build_ios.sh
```

The generated `Stickies.xcodeproj` is ignored by git. The project definition lives in `project.yml`.
