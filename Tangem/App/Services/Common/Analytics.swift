//
//  Analytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
#if !CLIP // [REDACTED_TODO_COMMENT]
import FirebaseAnalytics
import FirebaseCrashlytics
import AppsFlyerLib
import BlockchainSdk
import Amplitude
#endif
import TangemSdk

class Analytics {
    static func log(_ event: Event, params: [ParameterKey: String] = [:]) {
        let compatibles = event.analyticsSystems()
        for compatible in compatibles {
            switch compatible {
            case .appsflyer, .firebase:
                log(event: event, with: params)
            case .amplitude: // [REDACTED_TODO_COMMENT]
                let convertParams = params.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
            }
        }
    }

    static func log(_ category: Category, event: Event, params: [ParameterKey: String] = [:]) {
        let convertParams = params.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }

    }

    static func log(event: Event, with params: [ParameterKey: Any]? = nil) {
        #if !CLIP
        let key = event.rawValue
        let values = params?.firebaseParams
        FirebaseAnalytics.Analytics.logEvent(key, parameters: values)
        AppsFlyerLib.shared().logEvent(key, withValues: values)
        #endif
    }

    static func logScan(card: Card, config: UserWalletConfig) {
        log(event: .cardIsScanned, with: collectCardData(card))

        if DemoUtil().isDemoCard(cardId: card.cardId) {
            log(event: .demoActivated, with: [.cardId: card.cardId])
        }
    }

    static func logTx(blockchainName: String?, isPushed: Bool = false) {
        log(event: isPushed ? .transactionIsPushed : .transactionIsSent,
            with: [ParameterKey.blockchain: blockchainName ?? ""])
    }

    static func logCardSdkError(_ error: TangemSdkError, for action: Action, parameters: [ParameterKey: Any] = [:]) {
        #if !CLIP
        if case .userCancelled = error { return }

        var params = parameters
        params[.action] = action.rawValue
        params[.errorKey] = String(describing: error)

        let nsError = NSError(domain: "Tangem SDK Error #\(error.code)", code: error.code, userInfo: params.firebaseParams)
        Crashlytics.crashlytics().record(error: nsError)
        #endif
    }

    static func logCardSdkError(_ error: TangemSdkError, for action: Action, card: Card, parameters: [ParameterKey: Any] = [:]) {
        logCardSdkError(error, for: action, parameters: collectCardData(card, additionalParams: parameters))
    }

    static func log(error: Error) {
        #if !CLIP
        if case .userCancelled = error.toTangemSdkError() {
            return
        }

        if let detailedDescription = (error as? DetailedError)?.detailedDescription {
            var params = [ParameterKey: Any]()
            params[.errorDescription] = detailedDescription
            let nsError = NSError(domain: "DetailedError",
                                  code: 1,
                                  userInfo: params.firebaseParams)
            Crashlytics.crashlytics().record(error: nsError)
        } else {
            Crashlytics.crashlytics().record(error: error)
        }

        #endif
    }

    #if !CLIP
    static func logWcEvent(_ event: WalletConnectEvent) {
        var params = [ParameterKey: Any]()
        let firEvent: Event
        switch event {
        case let .error(error, action):
            if let action = action {
                params[.walletConnectAction] = action.rawValue
            }
            params[.errorDescription] = error.localizedDescription
            let nsError = NSError(domain: "WalletConnect Error for: \(action?.rawValue ?? "WC Service error")", code: 0, userInfo: params.firebaseParams)
            Crashlytics.crashlytics().record(error: nsError)
            return
        case .action(let action):
            params[.walletConnectAction] = action.rawValue
            firEvent = .wcSuccessResponse
        case .invalidRequest(let json):
            params[.walletConnectRequest] = json
            firEvent = .wcInvalidRequest
        case .session(let state, let url):
            switch state {
            case .connect:
                firEvent = .wcNewSession
            case .disconnect:
                firEvent = .wcSessionDisconnected
            }
            params[.walletConnectDappUrl] = url.absoluteString
        }

        log(event: firEvent, with: params)
    }
    #endif

    #if !CLIP
    static func logShopifyOrder(_ order: Order) {
        var appsFlyerDiscountParams: [String: Any] = [:]
        var firebaseDiscountParams: [String: Any] = [:]

        if let discountCode = order.discount?.code {
            appsFlyerDiscountParams[AFEventParamCouponCode] = discountCode
            firebaseDiscountParams[AnalyticsParameterCoupon] = discountCode
        }

        let sku = order.lineItems.first?.sku ?? "unknown"

        AppsFlyerLib.shared().logEvent(AFEventPurchase, withValues: appsFlyerDiscountParams.merging([
            AFEventParamContentId: sku,
            AFEventParamRevenue: order.total,
            AFEventParamCurrency: order.currencyCode,
        ], uniquingKeysWith: { $1 }))

        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventPurchase, parameters: firebaseDiscountParams.merging([
            AnalyticsParameterItems: [
                [AnalyticsParameterItemID: sku],
            ],
            AnalyticsParameterValue: order.total,
            AnalyticsParameterCurrency: order.currencyCode,
        ], uniquingKeysWith: { $1 }))
    }
    #endif

    static func logAmplitude(event: Event, params: [String: String] = [:]) {
        #if !CLIP
        let category = "[\(event.category().rawValue)]"
        Amplitude.instance().logEvent(event.rawValue.camelCaseToSnakeCase(), withEventProperties: params)
        #endif
    }

    private static func collectCardData(_ card: Card, additionalParams: [ParameterKey: Any] = [:]) -> [ParameterKey: Any] {
        var params = additionalParams
        params[.batchId] = card.batchId
        params[.firmware] = card.firmwareVersion.stringValue
        return params
    }
}

extension Analytics {
    enum Event: String {
        case cardIsScanned = "card_is_scanned"
        case transactionIsSent = "transaction_is_sent"
        case transactionIsPushed = "transaction_is_pushed"
        case readyToScan = "ready_to_scan"
        case displayRateAppWarning = "rate_app_warning_displayed"
        case negativeRateAppFeedback = "negative_rate_app_feedback"
        case positiveRateAppFeedback = "positive_rate_app_feedback"
        case dismissRateAppWarning = "dismiss_rate_app_warning"
        case wcSuccessResponse = "wallet_connect_success_response"
        case wcInvalidRequest = "wallet_connect_invalid_request"
        case wcNewSession = "wallet_connect_new_session"
        case wcSessionDisconnected = "wallet_connect_session_disconnected"
        case userBoughtCrypto = "user_bought_crypto"
        case userSoldCrypto = "user_sold_crypto"
        case getACard = "get_card"
        case demoActivated = "demo_mode_activated"

        // MARK: - Amplitude
        case signedIn = "Signed in"
        case toppedUp = "Topped up"
        case buttonTokensList = "Button - Tokens List"
        case buttonBuyCards = "Button - Buy Cards"
        case introductionProcessButtonScanCard = "Button - Scan Card"
        case introductionProcessCardWasScanned = "Card Was Scanned"
        case introductionProcessOpened = "Introduction Process Screen Opened"
        case buttonRequestSupport = "Button - Request Support"
        case shopScreenOpened = "Shop Screen Opened"
        case purchased = "Purchased"
        case redirected = "Redirected"
        case buttonBiometricSignIn = "Button - Biometric Sign In"
        case buttonCardSignIn = "Button - Card Sign In"
        case onboardingStarted = "Onboarding Started"
        case onboardingFinished = "Onboarding Finished"
        case createWalletScreenOpened = "Create Wallet Screen Opened"
        case buttonCreateWallet = "Button - Create Wallet"
        case walletCreatedSuccessfully = "Wallet Created Successfully"
        case backupScreenOpened = "Backup Screen Opened"
        case backupStarted = "Backup Started"
        case backupSkipped = "Backup Skipped"
        case settingAccessCodeStarted = "Setting Access Code Started"
        case accessCodeEntered = "Access Code Entered"
        case accessCodeReEntered = "Access Code Re-entered"
        case backupFinished = "Backup Finished"
        case activationScreenOpened = "Activation Screen Opened"
        case buttonBuyCrypto = "Button - Buy Crypto"
        case buttonShowTheWalletAddress = "Button - Show the Wallet Address"
        case enableBiometric = "Enable Biometric"
        case allowBiometricID = "Allow Face ID / Touch ID (System)"
        case twinningScreenOpened = "Twinning Screen Opened"
        case twinSetupStarted = "Twin Setup Started"
        case twinSetupFinished = "Twin Setup Finished"
        case screenOpened = "Screen opened"
        case buttonScanCard = "Button-Scan Card"
        case cardWasScanned = "Card Was Scanned "
        case buttonMyWallets = "Button - My Wallets"
        case mainCurrencyChanged = "Main Currency Changed"
        case noticeRateTheAppButtonTapped = "Notice - Rate The App Button Tapped"
        case noticeBackupYourWalletTapped = "Notice - Backup Your Wallet Tapped"
        case noticeScanYourCardTapped = "Notice - Scan Your Card Tapped"
        case refreshed = "Refreshed"
        case buttonManageTokens = "Button - Manage Tokens"
        case tokenIsTapped = "Token is Tapped"
        case detailsScreenOpened = "Details Screen Opened"
        case buttonRemoveToken = "Button - Remove Token"
        case buttonExplore = "Button - Explore"
        case buttonBuy = "Button - Buy"
        case buttonSell = "Button - Sell"
        case buttonExchange = "Button - Exchange"
        case buttonSend = "Button - Send"
        case recieveScreenOpened = "Recieve Screen Opened"
        case buttonCopyAddress = "Button - Copy Address"
        case buttonShareAddress = "Button - Share Address"
        case sendScreenOpened = "Send Screen Opened"
        case buttonPaste = "Button - Paste"
        case buttonQRCode = "Button - QR Code"
        case buttonSwapCurrency = "Button - Swap Currency"
        case transactionSent = "Transaction Sent"
        case topUpScreenOpened = "Top Up Screen Opened"
        case p2PScreenOpened = "P2P Screen Opened"
        case withdrawScreenOpened = "Withdraw Screen Opened"
        case manageTokensScreenOpened = "Manage Tokens Screen Opened"
        case tokenSearched = "Token Searched"
        case tokenSwitcherChanged = "Token Switcher Changed"
        case buttonSaveChanges = "Button - Save Changes"
        case buttonCustomToken = "Button - Custom Token"
        case customTokenScreenOpened = "Custom Token Screen Opened"
        case customTokenWasAdded = "Custom Token Was Added"
        case myWalletsScreenOpened = "My Wallets Screen Opened"
        case buttonScanNewCard = "Button - Scan New Card"
        case myWalletsCardWasScanned = " Card Was Scanned"
        case buttonUnlockAllWithFaceID = "Button - Unlock all with Face ID"
        case walletTapped = "Wallet Tapped"
        case buttonEditWalletTapped = "Button - Edit Wallet Tapped"
        case buttonDeleteWalletTapped = "Button - Delete Wallet Tapped"
        case buttonChat = "Button - Chat"
        case buttonSendFeedback = "Button - Send Feedback"
        case buttonStartWalletConnectSession = "Button - Start Wallet Connect Session "
        case buttonStopWalletConnectSession = "Button - Stop Wallet Connect Session"
        case buttonCardSettings = "Button - Card Settings"
        case buttonAppSettings = "Button - App Settings"
        case buttonCreateBackup = "Button - Create Backup"
        case buttonSocialNetwork = "Button - Social Network"
        case buttonFactoryReset = "Button - Factory Reset"
        case factoryResetFinished = "Factory Reset Finished"
        case buttonChangeUserCode = "Button - Change User Code"
        case userCodeChanged = "User Code Changed"
        case buttonChangeSecurityMode = "Button - Change Security Mode"
        case securityModeChanged = "Security Mode Changed"
        case faceIDSwitcherChanged = "Face ID Switcher Changed"
        case saveAccessCodeSwitcherChanged = "Save Access Code Switcher Changed"
        case buttonEnableBiometricAuthentication = "Button - Enable Biometric Authentication"
        case newSessionEstablished = "New Session Established"
        case sessionDisconnected = "Session Disconnected"
        case requestSigned = "Request Signed"
        case chatScreenOpened = "Chat Screen Opened"
        case settingsScreenOpened = "Settings Screen Opened"

        // MARK: -
        fileprivate static var nfcError: String {
            "nfc_error"
        }

        func category() -> Category {
            switch self {
            case .signedIn:
                return .basic
            case .toppedUp:
                return .basic
            case .introductionProcessOpened:
                return .introductionProcess
            case .introductionProcessCardWasScanned:
                return .introductionProcess
            case .introductionProcessButtonScanCard:
                return .introductionProcess
            case .buttonTokensList:
                return .introductionProcess
            case .buttonBuyCards:
                return .introductionProcess
            case .buttonRequestSupport:
                return .introductionProcess
            case .shopScreenOpened:
                return .shop
            case .purchased:
                return .shop
            case .redirected:
                return .shop
            case .buttonBiometricSignIn:
                return .signIn
            case .buttonCardSignIn:
                return .signIn
            case .onboardingStarted:
                return .onboarding
            case .onboardingFinished:
                return .onboarding
            case .createWalletScreenOpened:
                return .createWallet
            case .buttonCreateWallet:
                return .createWallet
            case .walletCreatedSuccessfully:
                return .createWallet
            case .backupScreenOpened:
                return .backup
            case .backupStarted:
                return .backup
            case .backupSkipped:
                return .backup
            case .settingAccessCodeStarted:
                return .backup
            case .accessCodeEntered:
                return .backup
            case .accessCodeReEntered:
                return .backup
            case .backupFinished:
                return .backup
            case .activationScreenOpened:
                return .topUp
            case .buttonBuyCrypto:
                return .topUp
            case .buttonShowTheWalletAddress:
                return .topUp
            case .enableBiometric:
                return .biometric
            case .allowBiometricID:
                return .biometric
            case .twinningScreenOpened:
                return .twins
            case .twinSetupStarted:
                return .twins
            case .twinSetupFinished:
                return .twins
            case .screenOpened:
                return .mainScreen
            case .buttonScanCard:
                return .mainScreen
            case .cardWasScanned:
                return .mainScreen
            case .buttonMyWallets:
                return .mainScreen
            case .mainCurrencyChanged:
                return .mainScreen
            case .noticeRateTheAppButtonTapped:
                return .mainScreen
            case .noticeBackupYourWalletTapped:
                return .mainScreen
            case .noticeScanYourCardTapped:
                return .mainScreen
            case .refreshed:
                return .token
            case .buttonManageTokens:
                return .token
            case .tokenIsTapped:
                return .token
            case .detailsScreenOpened:
                return .detailsScreen
            case .buttonRemoveToken:
                return .token
            case .buttonExplore:
                return .token
            case .buttonBuy:
                return .token
            case .buttonSell:
                return .token
            case .buttonExchange:
                return .token
            case .buttonSend:
                return .token
            case .recieveScreenOpened:
                return .tokenRecieve
            case .buttonCopyAddress:
                return .tokenRecieve
            case .buttonShareAddress:
                return .tokenRecieve
            case .sendScreenOpened:
                return .tokenSend
            case .buttonPaste:
                return .tokenSend
            case .buttonQRCode:
                return .tokenSend
            case .buttonSwapCurrency:
                return .tokenSend
            case .transactionSent:
                return .tokenSend
            case .topUpScreenOpened:
                return .tokenTopUp
            case .p2PScreenOpened:
                return .tokenTopUp
            case .withdrawScreenOpened:
                return .tokenWithdraw
            case .manageTokensScreenOpened:
                return .manageTokens
            case .tokenSearched:
                return .manageTokens
            case .tokenSwitcherChanged:
                return .manageTokens
            case .buttonSaveChanges:
                return .manageTokens
            case .buttonCustomToken:
                return .manageTokens
            case .customTokenScreenOpened:
                return .manageTokens
            case .customTokenWasAdded:
                return .manageTokens
            case .settingsScreenOpened:
                return .settings
            case .buttonChat:
                return .settings
            case .buttonSendFeedback:
                return .settings
            case .buttonStartWalletConnectSession:
                return .settings
            case .buttonStopWalletConnectSession:
                return .settings
            case .buttonCardSettings:
                return .settings
            case .buttonAppSettings:
                return .settings
            case .buttonCreateBackup:
                return .settings
            case .buttonSocialNetwork:
                return .settings
            case .buttonFactoryReset:
                return .appSettings
            case .factoryResetFinished:
                return .appSettings
            case .buttonChangeUserCode:
                return .appSettings
            case .userCodeChanged:
                return .appSettings
            case .buttonChangeSecurityMode:
                return .appSettings
            case .securityModeChanged:
                return .appSettings
            case .faceIDSwitcherChanged:
                return .appSettings
            case .saveAccessCodeSwitcherChanged:
                return .appSettings
            case .buttonEnableBiometricAuthentication:
                return .appSettings
            case .newSessionEstablished:
                return .walletConnect
            case .sessionDisconnected:
                return .walletConnect
            case .requestSigned:
                return .walletConnect
            case .chatScreenOpened:
                return .chat
            case .myWalletsScreenOpened:
                return .myWallets
            case .buttonScanNewCard:
                return .myWallets
            case .myWalletsCardWasScanned:
                return .myWallets
            case .buttonUnlockAllWithFaceID:
                return .myWallets
            case .walletTapped:
                return .myWallets
            case .buttonEditWalletTapped:
                return .myWallets
            case .buttonDeleteWalletTapped:
                return .myWallets
            default:
                return .uncategorized
            }
        }
    }

    enum Action: String {
        case scan = "tap_scan_task"
        case sendTx = "send_transaction"
        case pushTx = "push_transaction"
        case walletConnectSign = "wallet_connect_personal_sign"
        case walletConnectTxSend = "wallet_connect_tx_sign"
        case readPinSettings = "read_pin_settings"
        case changeSecOptions = "change_sec_options"
        case createWallet = "create_wallet"
        case purgeWallet = "purge_wallet"
        case deriveKeys = "derive_keys"
        case preparePrimary = "prepare_primary"
        case readPrimary = "read_primary"
        case addbackup = "add_backup"
        case proceedBackup = "proceed_backup"
    }

    enum ParameterKey: String {
        case blockchain = "blockchain"
        case batchId = "batch_id"
        case firmware = "firmware"
        case action = "action"
        case errorDescription = "error_description"
        case errorCode = "error_code"
        case newSecOption = "new_security_option"
        case errorKey = "Tangem SDK error key"
        case walletConnectAction = "wallet_connect_action"
        case walletConnectRequest = "wallet_connect_request"
        case walletConnectDappUrl = "wallet_connect_dapp_url"
        case currencyCode = "currency_code"
        case source = "source"
        case cardId = "cardId"
        case tokenName = "token_name"
        case type
        case currency = "Currency Type"
        case success
    }

    enum ParameterValue: String {
        case welcome
        case walletOnboarding = "wallet_onboarding"
    }

    enum AnalyticSystem {
        case firebase
        case amplitude
        case appsflyer
    }

    enum Category: String {
        case uncategorized
        case basic
        case introductionProcess
        case shop
        case onboarding
        case createWallet
        case backup
        case topUp
        case biometric
        case twins
        case mainScreen
        case portfolio
        case detailsScreen
        case token
        case tokenRecieve
        case tokenSend
        case tokenWithdraw
        case manageTokens
        case myWallets
        case settings
        case cardSettings
        case walletConnect
        case chat
        case appSettings
        case signIn
        case tokenTopUp

        var rawValue: String {
            switch self {
            case .basic:
                return "Basic"
            case .introductionProcess:
                return "Introduction Process"
            case .shop:
                return "Shop"
            case .onboarding:
                return "Onboarding"
            case .createWallet:
                return "Onboarding / Create Wallet"
            case .backup:
                return "Onboarding / Backup"
            case .topUp:
                return "Onboarding / Top Up"
            case .biometric:
                return "Onboarding / Biometric"
            case .twins:
                return "Onboarding / Twins"
            case .mainScreen:
                return "Main Screen"
            case .portfolio:
                return "Portfolio"
            case .detailsScreen:
                return "Details Screen"
            case .token:
                return "Token"
            case .tokenRecieve:
                return "Token / Recieve"
            case .tokenSend:
                return "Token / Send"
            case .tokenWithdraw:
                return "Token / Withdraw"
            case .manageTokens:
                return "Manage Tokens"
            case .myWallets:
                return "My Wallets"
            case .settings:
                return "Settings"
            case .cardSettings:
                return "Settings / Card Settings"
            case .walletConnect:
                return "Wallet Connect"
            case .chat:
                return "Chat"
            case .appSettings:
                return "Settings / App Settings"
            case .signIn:
                return "Sign In"
            case .tokenTopUp:
                return "Token / Topup"
            case .uncategorized:
                return ""
            }
        }
    }

    #if !CLIP
    enum WalletConnectEvent {
        enum SessionEvent {
            case disconnect
            case connect
        }

        case error(Error, WalletConnectAction?), session(SessionEvent, URL), action(WalletConnectAction), invalidRequest(json: String?)
    }
    #endif
}

//  MARK: - Amplitude events
extension Analytics.Event {
    func analyticsSystems() -> [Analytics.AnalyticSystem] {
        switch self {
        case .signedIn,
             .toppedUp,
             .buttonTokensList,
             .buttonBuyCards,
             .introductionProcessButtonScanCard,
             .introductionProcessCardWasScanned,
             .introductionProcessOpened,
             .buttonRequestSupport,
             .shopScreenOpened,
             .purchased,
             .redirected,
             .buttonBiometricSignIn,
             .buttonCardSignIn,
             .onboardingStarted,
             .onboardingFinished,
             .createWalletScreenOpened,
             .buttonCreateWallet,
             .walletCreatedSuccessfully,
             .backupScreenOpened,
             .backupStarted,
             .backupSkipped,
             .settingAccessCodeStarted,
             .accessCodeEntered,
             .accessCodeReEntered,
             .backupFinished,
             .activationScreenOpened,
             .buttonBuyCrypto,
             .buttonShowTheWalletAddress,
             .enableBiometric,
             .allowBiometricID,
             .twinningScreenOpened,
             .twinSetupStarted,
             .twinSetupFinished,
             .screenOpened,
             .buttonScanCard,
             .cardWasScanned,
             .buttonMyWallets,
             .mainCurrencyChanged,
             .noticeRateTheAppButtonTapped,
             .noticeBackupYourWalletTapped,
             .noticeScanYourCardTapped,
             .refreshed,
             .buttonManageTokens,
             .tokenIsTapped,
             .detailsScreenOpened,
             .buttonRemoveToken,
             .buttonExplore,
             .buttonBuy,
             .buttonSell,
             .buttonExchange,
             .buttonSend,
             .recieveScreenOpened,
             .buttonCopyAddress,
             .buttonShareAddress,
             .sendScreenOpened,
             .buttonPaste,
             .buttonQRCode,
             .buttonSwapCurrency,
             .transactionSent,
             .topUpScreenOpened,
             .p2PScreenOpened,
             .withdrawScreenOpened,
             .manageTokensScreenOpened,
             .tokenSearched,
             .tokenSwitcherChanged,
             .buttonSaveChanges,
             .buttonCustomToken,
             .customTokenScreenOpened,
             .customTokenWasAdded,
             .settingsScreenOpened,
             .buttonChat,
             .buttonSendFeedback,
             .buttonStartWalletConnectSession,
             .buttonStopWalletConnectSession,
             .buttonCardSettings,
             .buttonAppSettings,
             .buttonCreateBackup,
             .buttonSocialNetwork,
             .buttonFactoryReset,
             .factoryResetFinished,
             .buttonChangeUserCode,
             .userCodeChanged,
             .buttonChangeSecurityMode,
             .securityModeChanged,
             .faceIDSwitcherChanged,
             .saveAccessCodeSwitcherChanged,
             .buttonEnableBiometricAuthentication,
             .newSessionEstablished,
             .sessionDisconnected,
             .requestSigned,
             .myWalletsScreenOpened,
             .buttonScanNewCard,
             .myWalletsCardWasScanned,
             .buttonUnlockAllWithFaceID,
             .walletTapped,
             .buttonEditWalletTapped,
             .buttonDeleteWalletTapped,
             .chatScreenOpened:
            return [.amplitude]
        case .transactionIsSent:
            return [.firebase, .appsflyer, .amplitude]
        case .cardIsScanned,
             .transactionIsPushed,
             .readyToScan,
             .displayRateAppWarning,
             .negativeRateAppFeedback,
             .positiveRateAppFeedback,
             .dismissRateAppWarning,
             .wcSuccessResponse,
             .wcInvalidRequest,
             .wcNewSession,
             .wcSessionDisconnected,
             .userBoughtCrypto,
             .userSoldCrypto,
             .getACard,
             .demoActivated:
            return [.firebase, .appsflyer]
        }
    }
}

fileprivate extension Dictionary where Key == Analytics.ParameterKey, Value == Any {
    var firebaseParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}
