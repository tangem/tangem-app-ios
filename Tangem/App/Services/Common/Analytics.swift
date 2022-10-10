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
                logAmplitude(.onboarding, event: event, params: convertParams)
                break
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

    static func logAmplitude(_ category: Category, event: Event, params: [String: String] = [:]) {
        #if !CLIP
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
        case buttonTokensList
        case buttonBuyCards
        case buttonRequestSupport
        case shopScreenOpened
        case purchased
        case redirected
        case buttonBiometricSignIn
        case buttonCardSignIn
        case onboardingStarted
        case onboardingFinished
        case createWalletScreenOpened
        case buttonCreateWallet
        case walletCreatedSuccessfully
        case backupScreenOpened
        case backupStarted
        case backupSkipped
        case settingAccessCodeStarted
        case accessCodeEntered
        case accessCodeReEntered
        case backupFinished
        case activationScreenOpened
        case buttonBuyCrypto
        case buttonShowTheWalletAddress
        case enableBiometric
        case allowBiometricID
        case twinningScreenOpened
        case twinSetupStarted
        case twinSetupFinished
        case screenOpened
        case buttonScanCard
        case cardWasScanned
        case buttonMyWallets
        case mainCurrencyChanged
        case noticeRateTheAppButtonTapped
        case noticeBackupYourWalletTapped
        case noticeScanYourCardTapped
        case refreshed
        case buttonManageTokens
        case tokenIsTapped
        case detailsScreenOpened
        case buttonRemoveToken
        case buttonExplore
        case buttonBuy
        case buttonSell
        case buttonExchange
        case buttonSend
        case recieveScreenOpened
        case buttonCopyAddress
        case buttonShareAddress
        case sendScreenOpened
        case buttonPaste
        case buttonQRCode
        case buttonSwapCurrency
        case transactionSent
        case topUpScreenOpened
        case p2PScreenOpened
        case withdrawScreenOpened
        case manageTokensScreenOpened
        case tokenSearched
        case tokenSwitcherChanged
        case buttonSaveChanges
        case buttonCustomToken
        case customTokenScreenOpened
        case customTokenWasAdded
        case settingsScreenOpened
        case buttonChat
        case buttonSendFeedback
        case buttonStartWalletConnectSession
        case buttonStopWalletConnectSession
        case buttonCardSettings
        case buttonAppSettings
        case buttonCreateBackup
        case buttonSocialNetwork
        case buttonFactoryReset
        case factoryResetFinished
        case buttonChangeUserCode
        case userCodeChanged
        case buttonChangeSecurityMode
        case securityModeChanged
        case faceIDSwitcherChanged
        case saveAccessCodeSwitcherChanged
        case buttonEnableBiometricAuthentication
        case newSessionEstablished
        case sessionDisconnected
        case requestSigned
        case chatScreenOpened

        // MARK: -
        case viewStoryIntro
        case viewStoryWallet
        case viewStoryKeys
        case viewStoryCurrencies
        case viewStoryDefi
        case viewStoryEverybody
        case tokenListTapped
        case searchToken
        case buyBottomTapped
        case firstScan
        case secondScan
        case supportTapped
        case tryAgainTapped
        case createWalletTapped
        case backupTapped
        case backupLaterTapped
        case firstCardScan
        case addBackupCard
        case backupFinish
        case createAccessCode
        case accessCodeConfirm
        case cardCodeSave
        case backupCardSave
        case onboardingSuccess
        case mainPageEnter
        case mainPageRefresh
        case currencyTypeTapped
        case currencyTypeChanged
        case settingsTapped
        case manageTokensTapped
        case tokenTapped
        case scanCardTapped
        case chatTapped
        case wcTapped
        case factoryResetTapped
        case factoryResetSuccess
        case createBackupTapped
        case makeCommentTapped
        case walletConnectSuccessResponse
        case walletConnectInvalidRequest
        case walletConnectNewSession
        case walletConnectSessionDisconnected
        case tokenSearch
        case tokenSwitchOn
        case tokenSwitchOff
        case tokenListSave
        case сustomTokenTapped
        case customTokenSave
        case removeTokenTapped
        case copyAddressTapped
        case shareAddressTapped
        case exploreAddressTapped
        case cardSettingsTapped
        case appSettingsTapped
        case buyTokenTapped
        case p2pInstructionTapped
        case sendTokenTapped

        // MARK: -
        fileprivate static var nfcError: String {
            "nfc_error"
        }

        func category() {
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
        case currency
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

        var rawValue: String {
            switch self {
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
        case .viewStoryIntro,
             .viewStoryWallet,
             .viewStoryKeys,
             .viewStoryCurrencies,
             .viewStoryDefi,
             .viewStoryEverybody,
             .tokenListTapped,
             .searchToken,
             .buyBottomTapped,
             .firstScan,
             .secondScan,
             .supportTapped,
             .tryAgainTapped,
             .createWalletTapped,
             .backupTapped,
             .backupLaterTapped,
             .firstCardScan,
             .addBackupCard,
             .backupFinish,
             .createAccessCode,
             .accessCodeConfirm,
             .cardCodeSave,
             .backupCardSave,
             .onboardingSuccess,
             .mainPageEnter,
             .mainPageRefresh,
             .currencyTypeTapped,
             .currencyTypeChanged,
             .settingsTapped,
             .manageTokensTapped,
             .tokenTapped,
             .scanCardTapped,
             .chatTapped,
             .wcTapped,
             .factoryResetTapped,
             .factoryResetSuccess,
             .createBackupTapped,
             .makeCommentTapped,
             .walletConnectSuccessResponse,
             .walletConnectInvalidRequest,
             .walletConnectNewSession,
             .walletConnectSessionDisconnected,
             .tokenSearch,
             .tokenSwitchOn,
             .tokenSwitchOff,
             .tokenListSave,
             .сustomTokenTapped,
             .customTokenSave,
             .removeTokenTapped,
             .copyAddressTapped,
             .shareAddressTapped,
             .buyTokenTapped,
             .p2pInstructionTapped,
             .exploreAddressTapped,
             .cardSettingsTapped,
             .appSettingsTapped,
             .sendTokenTapped:
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
