# CloudKit Signing

Stickies sync uses the private CloudKit database in this container:

```text
iCloud.dev.rspcunningham.stickies
```

The macOS bundle identifier is:

```text
dev.rspcunningham.stickies
```

To run iCloud sync locally, the app must be signed with a provisioning profile
that enables CloudKit for that bundle ID and container. A certificate alone is
not enough; macOS rejects the protected iCloud entitlement at launch without a
matching embedded profile.

Development run:

```sh
PROVISIONING_PROFILE="/path/to/Stickies.provisionprofile" \
CODESIGN_IDENTITY="Apple Development: Robin Cunningham (H7J96JL786)" \
./script/build_and_run.sh --verify
```

Distribution/notarization builds should use a Developer ID Application identity,
a production-capable profile for the same app/container, and hardened runtime:

```sh
PROVISIONING_PROFILE="/path/to/Stickies.provisionprofile" \
CODESIGN_IDENTITY="Developer ID Application: Robin Cunningham (K5PRHP9Q23)" \
APS_ENVIRONMENT=production \
./script/build_and_run.sh --verify
```

The script falls back to ad-hoc signing when `CODESIGN_IDENTITY` is unset. That
keeps normal local development launching, but CloudKit sync is disabled because
the app has no iCloud entitlement in that mode.
