# Tangem for iPhone

[App Store](https://itunes.apple.com/app/tangem-lite/id1354868448)

[Homepage](https://tangem.com )

---

### Build on Device

1. **Ensure all required dependencies are installed:**

   * **Xcode** — Make absolutely sure you have the correct version installed, as specified in the `.xcode-version` file. You can download it from [XcodeReleases](https://xcodereleases.com/) or the [Apple Developer Portal](https://developer.apple.com/download/all/).

2. **Clone the repository:**

   ```bash
   git clone https://github.com/tangem/tangem-app-ios-public.git
   ```

3. **Run the bootstrap script:**

   ```bash
   cd tangem-app-ios-public && ./bootstrap.sh
   ```

4. **Open the project in Xcode and select a build scheme.** Valid schemes are:

   * `Tangem`
   * `Tangem Alpha`
   * `Tangem Beta`

5. **Select a valid signing identity in Xcode.**
Make sure to choose your own valid signing certificate and provisioning profile in the Xcode project settings (under **Signing & Capabilities**).

6. **\[Optional] Add API keys if needed.**
   Some blockchain networks require private API keys for interaction. Add your keys to the appropriate config files:

   * `config_dev.json`
   * `config_alpha.json`
   * `config_beta.json`
   * `config_prod.json`

7. **Build the selected scheme.**


