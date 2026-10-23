# Tangem Pay

Tangem Pay is a payment account backed by stablecoin balances: the Paera backend keeps the customer, balances and orders, and Rain issues the cards. Every user wallet gets at most one such account. 

It is not a crypto account: it holds no wallet models and its balance is not derived from the chain by the app.

## Naming

Everything that belongs to the feature is prefixed `TangemPay`: the SPM module `Modules/TangemPay`, the app-side glue in `Tangem/Features/Visa/TangemPay`, and the screen folders `Tangem/Features/Main/Visa/TangemPay*`.

## Legacy Visa

Everything else named `Visa*` is the legacy hardware Visa card product and not Tangem Pay: the `TangemVisa/` framework target, the app-side models and the screen folders that carry the prefix. It is gated by `Feature.visa` and still wired.

Exceptions that carry the old Visa name but are Tangem Pay: `VisaAPIType`, `VisaCustomerInfoResponse`, `VisaKYCAccessTokenResponse`, and the tester-menu setting "Visa API type" (`FeatureStorage.visaAPIType`).

## Account model and derivation

The account enters the accounts domain as `AccountModel.tangemPay(any TangemPayAccountModel)`. It is not a `CryptoAccountModel`, has no `AccountType` case, cannot be created by the user and produces no wallet models. 

It contributes a single token item to the wallet, the canonical one exposed by `TangemPayAccount`. Under the hood the account holds one `TangemPayAccountToken` per token per network it is issued on, built by `TangemPayAccountTokensResolver`; funding and withdrawal pick from those and fall back to the canonical token.

`TangemPayManager` is the only implementation of `TangemPayAccountModel`. `TangemPayAccountId` wraps the `UserWalletId`, which is what enforces one account per wallet.

`TangemPayBuilder` is the per-wallet composition root: it builds the manager for every wallet on wallet load, regardless of enrollment. The account shows up in the account list only once the wallet is a Paera customer (`isPaeraCustomerPublisher`).

The feature has its own key. `FeatureDerivationPaths.tangemPay` is derived on demand during enrollment for both card and mobile wallets by the `TangemPayAuthorizing` interactors and stored in `KeysRepository`. `TangemPayUtilities` turns the public key into the customer's wallet address, which is the identity the backend authorizes.

## Entry points

- **Enrollment / offer:** `TangemPayOnboardingCoordinator` → `TangemPayOfferViewModel` → `AccountModelsManager.authorizeTangemPayOfferForResidency`.
- **Account screen:** `TangemPayMainCoordinator` with `TangemPayMainViewModel`, pushed by `MainCoordinator.openTangemPayMainView`. Deep links and push notifications arrive as `TangemPayOpeningAction`.
- **Main-screen row:** `TangemPayAccountViewModel`, produced by `TangemPayAccountAggregator` from `MultiWalletMainContentViewModel`. Its tap handler switches on the local state.
- **Enrolled account object handed to the UI:** `TangemPayAccount`.

## State machine

The state flows in one direction and each layer owns exactly one representation:

backend customer info (`VisaCustomerInfoResponse`) → `TangemPayEnrollmentState`, computed by `TangemPayEnrollmentStateFetcher` in the module → `TangemPayLocalState`, owned by `TangemPayManager.refreshState()` in the app → UI decisions in `TangemPayAccountViewModel`.

`TangemPayCachedLocalState` is the persisted subset used to render the main-screen row before the first refresh completes.

## UI tests

UI tests under `TangemUITests/Tests/TangemPay` and their page objects under `TangemUITests/Screens/TangemPay` are always updated separately from feature work. A feature change leaves them untouched, even when it breaks an existing test; the tests are brought in line in their own change.
