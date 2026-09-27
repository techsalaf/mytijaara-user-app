# Google Play release audit — 2026-09-25

Release: `com.mytijaara.app`, version `1.0.1`, version code `2`, target API 36.

## Corrected in this release

- Explicitly remove Google advertising ID and Privacy Sandbox advertising permissions during manifest merging. Disable Facebook advertiser ID collection and automatic app event logging to match the stated no-advertising-ID declaration.
- Use Android's Firebase configuration generated from `google-services.json`, replacing the template project's hardcoded startup options.
- Correct the Apple sign-in callback class to the installed plugin's class.
- Replace the template deep-link host with `app.mytijaara.com` and the remaining Android app-name resource with MyTijaara.
- Remove obsolete legacy external-storage mode. Existing broad photo/video/audio permission removal rules remain in place.
- Keep signing keys out of Git. Release signing and the version increment supplied by the owner are retained.

## Unresolved before submission

1. **Privacy policy is empty.** Read-only live requests to `https://dashboard.mytijaara.com/api/v1/privacy-policy`, both without headers and with the app's English localization header, returned HTTP 200 with JSON `""`. This is the endpoint used by the in-app privacy screen. Publish accurate policy content in the admin/backend and verify the public policy URL in Play Console. Terms at `/api/v1/terms-and-conditions` also returned `""`.
2. **Social sign-in configuration is incomplete.** The live configuration enables Google and Facebook login. `AppConstants.googleServerClientId` still belongs to the old `stackmart-500c7` project, while the new `google-services.json` belongs to `mytijaara-21638` and contains no OAuth clients. Android Facebook resources still use template credentials. Configure owned OAuth/Facebook applications and release/Play signing fingerprints, then test login; alternatively disable those methods in the backend until configured. Credentials were not invented or silently substituted.
3. **External account deletion must be verified.** In-app deletion exists under Profile → Edit Profile → overflow menu → Delete account and invokes the backend removal endpoint. This audit did not delete a real account or verify backend retention behavior. Play also requires an external deletion-request URL in Console; its existence and Console configuration were not verified.
4. **App-link association is missing.** `https://app.mytijaara.com/.well-known/assetlinks.json` returned 404. Publish the correct association for this package and the Play app-signing certificate. This affects verified links; it is not by itself proof of rejection.
5. **Console and device checks remain necessary.** Verify Data safety against Firebase, Facebook, location, microphone, uploads, notifications, and backend processing; provide reviewer access that works despite OTP; verify store listing/content rating and any pharmacy/regulated-product declarations against actual offerings. Confirm code 2 is unused and the upload certificate matches the existing Play application. No Android device was connected for login, checkout, permission-denial, deletion, or runtime 16 KB testing.

## Additional observations

- Production API uses HTTPS; release manifest disables cleartext traffic. No background-location, SMS, call-log, all-files, or package-install permissions are intentionally requested by the source manifest.
- The AI chat implementation has no reporting flow found in the inspected feature. Live `ai_chat_status` and `open_ai_status` were both 0. Reassess Google's AI-content/reporting requirements before enabling it. Review moderation/reporting obligations for reviews/chat/reels according to who can publish content.
- `test/widget_test.dart` is the untouched Flutter counter example and does not represent this application's behavior.
- Static inspection cannot guarantee Play approval. Server content, SDK configuration, signing identity, Console declarations, and runtime behavior also matter.

## Policy references

- [Target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [User data and privacy policy](https://support.google.com/googleplay/android-developer/answer/10144311)
- [Photo and video permissions](https://support.google.com/googleplay/android-developer/answer/14115180)
- [16 KB page-size verification](https://developer.android.com/guide/practices/page-sizes)
- [AI-generated content](https://support.google.com/googleplay/android-developer/answer/13985936)
