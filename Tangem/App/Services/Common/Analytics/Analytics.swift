//
//  Analytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import AppsFlyerLib
import BlockchainSdk
import Amplitude
import TangemSdk

enum Analytics {
    static private var analyticsSystems: [Analytics.AnalyticSystem] = [.firebase, .appsflyer, .amplitude]
    static private var persistentParams: [ParameterKey: String] = [:]

    static func reset() {
        persistentParams = [:]
    }

    static func log(_ event: Event, params: [ParameterKey: String] = [:]) {
        for system in analyticsSystems {
            switch system {
            case .appsflyer, .firebase:
                log(event: event, with: params)
            case .amplitude:
                logAmplitude(event: event, params: params)
            }
        }
        logCrashlytics(event, with: params.firebaseParams)
    }

    static func logScan(card: Card, config: UserWalletConfig) {
        persistentParams[.batchId] = card.batchId

        log(event: .cardIsScanned, with: collectCardData(card))

        if DemoUtil().isDemoCard(cardId: card.cardId) {
            log(event: .demoActivated, with: [.cardId: card.cardId])
        }
    }

    static func logTx(blockchainName: String?, isPushed: Bool = false) {
        let event: Event = isPushed ? .transactionIsPushed : .transactionIsSent
        let params = [ParameterKey.blockchain: blockchainName ?? ""]
        log(event, params: params)
    }

    static func logCardSdkError(_ error: TangemSdkError, for action: Action, parameters: [ParameterKey: String] = [:]) {
        if case .userCancelled = error { return }

        var params = parameters
        params[.action] = action.rawValue
        params[.errorKey] = String(describing: error)

        let nsError = NSError(domain: "Tangem SDK Error #\(error.code)", code: error.code, userInfo: params.firebaseParams)
        Crashlytics.crashlytics().record(error: nsError)
    }

    static func logCardSdkError(_ error: TangemSdkError, for action: Action, card: Card, parameters: [ParameterKey: String] = [:]) {
        logCardSdkError(error, for: action, parameters: collectCardData(card, additionalParams: parameters))
    }

    static func log(error: Error) {
        if case .userCancelled = error.toTangemSdkError() {
            return
        }

        if let detailedDescription = (error as? DetailedError)?.detailedDescription {
            var params = [ParameterKey: String]()
            params[.errorDescription] = detailedDescription
            let nsError = NSError(domain: "DetailedError",
                                  code: 1,
                                  userInfo: params.firebaseParams)
            Crashlytics.crashlytics().record(error: nsError)
        } else {
            Crashlytics.crashlytics().record(error: error)
        }
    }

    static func logCrashlytics(_ event: Event, with params: [String: Any] = [:]) {
        if AppEnvironment.current.isXcodePreview {
            return
        }

        let message = "\(event.rawValue).\(params.isEmpty ? "" : " \(params.description)")"
        Crashlytics.crashlytics().log(message)
    }

    static func logWcEvent(_ event: WalletConnectEvent) {
        var params = [ParameterKey: String]()
        let firEvent: Event
        switch event {
        case let .error(error, action):
            if let action = action {
                params[.walletConnectAction] = action.rawValue
            }
            params[.errorDescription] = error.localizedDescription
            let nsError = NSError(domain: "WalletConnect Error for: \(action?.rawValue ?? "WC Service error")",
                                  code: 0,
                                  userInfo: params.firebaseParams)
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

        log(firEvent, params: params)
    }

    static func logShopifyOrder(_ order: Order) {
        var appsFlyerDiscountParams: [String: Any] = [:]
        var firebaseDiscountParams: [String: Any] = [:]
        var amplitudeDiscountParams: [ParameterKey: String] = [:]

        if let discountCode = order.discount?.code {
            appsFlyerDiscountParams[AFEventParamCouponCode] = discountCode
            firebaseDiscountParams[AnalyticsParameterCoupon] = discountCode
            amplitudeDiscountParams[.couponCode] = discountCode
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

        logAmplitude(event: .purchased, params: amplitudeDiscountParams.merging([
            .sku: sku,
            .count: "\(order.lineItems.count)",
            .amount: "\(order.total)\(order.currencyCode)",
        ], uniquingKeysWith: { $1 }))
    }

    private static func logAmplitude(event: Event, params: [ParameterKey: String] = [:]) {
        let mergedParams = params.merging(persistentParams, uniquingKeysWith: { (current, _) in  current })
        let convertedParams = mergedParams.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
        Amplitude.instance().logEvent(event.rawValue, withEventProperties: convertedParams)
    }

    private static func log(event: Event, with params: [ParameterKey: String]? = nil) {
        let key = event.rawValue

        let mergedParams = params?.merging(persistentParams, uniquingKeysWith: { (current, _) in  current })
        let values = mergedParams?.firebaseParams

        FirebaseAnalytics.Analytics.logEvent(key, parameters: values)
        AppsFlyerLib.shared().logEvent(key, withValues: values)
    }

    private static func collectCardData(_ card: Card, additionalParams: [ParameterKey: String] = [:]) -> [ParameterKey: String] {
        var params = additionalParams
        params[.firmware] = card.firmwareVersion.stringValue
        params[.currency] = card.walletCurves.reduce("", { $0 + $1.rawValue })
        return params
    }
}

extension Analytics {
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
        case token = "Token"
        case derivationPath = "Derivation Path"
        case networkId = "Network Id"
        case contractAddress = "Contract Address"
        case mode = "Mode"
        case state = "State"
        case basicCurrency = "Currency"
        case batch = "Batch"
        case cardsCount = "Cards count"
        case sku = "SKU"
        case amount = "Amount"
        case count = "Count"
        case couponCode = "Coupon Code"
    }

    enum ParameterValue: String {
        case welcome
        case walletOnboarding = "wallet_onboarding"
        case on = "On"
        case off = "Off"
    }

    enum AnalyticSystem {
        case firebase
        case amplitude
        case appsflyer
    }

    enum WalletConnectEvent {
        enum SessionEvent {
            case disconnect
            case connect
        }

        case error(Error, WalletConnectAction?), session(SessionEvent, URL), action(WalletConnectAction), invalidRequest(json: String?)
    }
}

fileprivate extension Dictionary where Key == Analytics.ParameterKey, Value == String {
    var firebaseParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}
