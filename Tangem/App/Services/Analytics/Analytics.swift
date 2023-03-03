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

class Analytics {
    @Injected(\.analyticsContext) private static var analyticsContext: AnalyticsContext

    private init() {}

    // MARK: - Scan

    static func beginLoggingCardScan(source: CardScanSource) {
        analyticsContext.set(value: source, forKey: .scanSource, scope: .common)
        logInternal(source.cardScanButtonEvent)
    }

    static func endLoggingCardScan() {
        guard let source = analyticsContext.value(forKey: .scanSource, scope: .common) as? CardScanSource else {
            assertionFailure("Don't forget to call beginLoggingCardScan")
            return
        }

        analyticsContext.removeValue(forKey: .scanSource, scope: .common)
        logInternal(.cardWasScanned, params: [.commonSource: source.cardWasScannedParameterValue.rawValue])

        if let cardId = analyticsContext.contextData?.analyticsParams[.cardId],
           DemoUtil().isDemoCard(cardId: cardId) {
            log(event: .demoActivated, params: [.cardId: cardId])
        }
    }

    // MARK: - Others

    static func logSignInIfNeeded(balance: Decimal) {
        let isSignedIn = analyticsContext.value(forKey: .signedIn, scope: .userWallet) as? Bool ?? false
        if isSignedIn {
            return
        }

        analyticsContext.set(value: true, forKey: .signedIn, scope: .userWallet)

        let params: [ParameterKey: String] = [
            .state: ParameterValue.state(for: balance).rawValue,
        ]

        logInternal(.signedIn, params: params)
    }

    static func logTopUpIfNeeded(balance: Decimal) {
        let previousBalance = analyticsContext.value(forKey: .balance, scope: .userWallet) as? Decimal

        // Send only first topped up event. Do not send the event to analytics on following topup events.
        if balance > 0, previousBalance == 0 {
            logInternal(.toppedUp)
            analyticsContext.set(value: balance, forKey: .balance, scope: .userWallet)
        } else if previousBalance == nil { // Do not save in a withdrawal case
            // Register the first app launch with the zero balance.
            analyticsContext.set(value: balance, forKey: .balance, scope: .userWallet)
        }
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

        logInternal(.purchased, params: amplitudeDiscountParams.merging([
            .sku: sku,
            .count: "\(order.lineItems.count)",
            .amount: "\(order.total) \(order.currencyCode)",
        ], uniquingKeysWith: { $1 }))
    }

    // MARK: - Common

    static func log(_ event: Event, params: [ParameterKey: ParameterValue] = [:]) {
        log(event: event, params: params.mapValues { $0.rawValue })
    }

    static func log(event: Event, params: [ParameterKey: String]) {
        assert(event.canBeLoggedDirectly)

        logInternal(event, params: params)
    }

    // MARK: - Private

    fileprivate static func log(error: Error, params: [ParameterKey: String] = [:]) {
        var params = params

        if error is WalletConnectV2Error || error is WalletConnectServiceError {
            params[.errorDescription] = error.localizedDescription
            let nsError = NSError(
                domain: "WalletConnect Error",
                code: 0,
                userInfo: params.firebaseParams
            )
            Crashlytics.crashlytics().record(error: nsError)
        } else if let sdkError = error as? TangemSdkError {
            params[.errorKey] = String(describing: sdkError)
            let nsError = NSError(
                domain: "Tangem SDK Error #\(sdkError.code)",
                code: sdkError.code,
                userInfo: params.firebaseParams
            )
            Crashlytics.crashlytics().record(error: nsError)
        } else if let detailedDescription = (error as? DetailedError)?.detailedDescription {
            params[.errorDescription] = detailedDescription
            let nsError = NSError(
                domain: "DetailedError",
                code: 1,
                userInfo: params.firebaseParams
            )
            Crashlytics.crashlytics().record(error: nsError)
        } else {
            Crashlytics.crashlytics().record(error: error)
        }
    }

    private static func logInternal(
        _ event: Event,
        params: [ParameterKey: String] = [:],
        analyticsSystems: [Analytics.AnalyticsSystem] = [.firebase, .appsflyer, .amplitude]
    ) {
        if AppEnvironment.current.isXcodePreview {
            return
        }

        var params = params

        if let contextualParams = analyticsContext.contextData?.analyticsParams {
            params.merge(contextualParams, uniquingKeysWith: { _, new in new })
        }

        for system in analyticsSystems {
            switch system {
            case .appsflyer, .firebase:
                let key = event.rawValue
                let values = params.firebaseParams

                FirebaseAnalytics.Analytics.logEvent(key, parameters: values)
                AppsFlyerLib.shared().logEvent(key, withValues: values)

                let message = "\(key).\(values)"
                Crashlytics.crashlytics().log(message)
            case .amplitude:
                let convertedParams = params.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
                Amplitude.instance().logEvent(event.rawValue, withEventProperties: convertedParams)
            }
        }

        let printableParams: [String: String] = params.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
        if let data = try? JSONSerialization.data(withJSONObject: printableParams, options: .sortedKeys),
           let paramsString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: ",\"", with: ", \"") {
            let logMessage = "Analytics event: \(event.rawValue). Params: \(paramsString)"
            AppLog.shared.debug(logMessage)
        }
    }
}

// MARK: - Private

fileprivate extension Dictionary where Key == Analytics.ParameterKey, Value == String {
    var firebaseParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}

fileprivate extension Analytics.Event {
    var canBeLoggedDirectly: Bool {
        switch self {
        case .introductionProcessButtonScanCard,
             .buttonScanCard,
             .buttonScanNewCard,
             .buttonCardSignIn,
             .cardWasScanned,
             .signedIn,
             .toppedUp,
             .purchased:
            return false
        default:
            return true
        }
    }
}

// MARK: - AppLog error extension

extension AppLog {
    func error(_ error: Error, params: [Analytics.ParameterKey: Analytics.ParameterValue] = [:]) {
        self.error(error: error, params: params.mapValues { $0.rawValue })
    }

    func error(error: Error, params: [Analytics.ParameterKey: String]) {
        guard !error.toTangemSdkError().isUserCancelled else {
            return
        }

        Log.error(error)
        Analytics.log(error: error, params: params)
    }
}
