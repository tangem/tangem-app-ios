//
//  Analytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import AppsFlyerLib
import FirebaseAnalytics
import FirebaseCrashlytics
import BlockchainSdk
import TangemSdk
import TangemFoundation

class Analytics {
    @Injected(\.analyticsContext) private static var analyticsContext: AnalyticsSessionContext

    private static let firebaseLoggingQueue = DispatchQueue(
        label: "com.tangem.Analytics.firebaseLoggingQueue",
        target: .global(qos: .utility)
    )

    private init() {}

    // MARK: - Others

    static func logTopUpIfNeeded(balance: Decimal, for userWalletId: UserWalletId, contextParams: Analytics.ContextParams = .default) {
        let hasPreviousPositiveBalance = analyticsContext.value(forKey: .hasPositiveBalance, scope: .userWallet(userWalletId)) as? Bool

        // Send only first topped up event. Do not send the event to analytics on following topup events.
        if balance > 0, hasPreviousPositiveBalance == false {
            logEventInternal(.toppedUp, contextParams: contextParams)
            logEventInternal(.afWalletFunded, analyticsSystems: [.appsFlyer], contextParams: contextParams)
            analyticsContext.set(value: true, forKey: .hasPositiveBalance, scope: .userWallet(userWalletId))
        } else if hasPreviousPositiveBalance == nil { // Do not save in a withdrawal case
            // Register the first app launch with balance.
            analyticsContext.set(value: balance > 0, forKey: .hasPositiveBalance, scope: .userWallet(userWalletId))
        }
    }

    static func logPromotionEvent(_ event: Event, programName: String, newClient: Bool? = nil) {
        var params = [
            ParameterKey.programName: programName,
        ]

        if let newClient {
            let clientType: ParameterValue = newClient ? .new : .old
            params[.clientType] = clientType.rawValue
        }

        Analytics.log(event: event, params: params)
    }

    static func logScanError(_ error: Error, source: Analytics.ScanErrorsSource, contextParams: Analytics.ContextParams = .default) {
        let error = error.toTangemSdkError()

        Analytics.log(
            event: .scanErrors,
            params: [
                .errorCode: "\(error.code)",
                .errorMessage: error.localizedDescription,
                .source: source.parameterValue.rawValue,
            ],
            contextParams: contextParams
        )
    }

    // MARK: - Common

    static func log(
        _ event: Event,
        params: [ParameterKey: ParameterValue] = [:],
        contextParams: Analytics.ContextParams = .default,
        limit: Analytics.EventLimit = .unlimited
    ) {
        log(
            event: event,
            params: params.mapValues { $0.rawValue },
            contextParams: contextParams,
            limit: limit
        )
    }

    static func log(
        event: Event,
        params: [ParameterKey: String],
        analyticsSystems: [Analytics.AnalyticsSystem] = [.firebase, .amplitude, .crashlytics],
        contextParams: Analytics.ContextParams = .default,
        limit: Analytics.EventLimit = .unlimited
    ) {
        assert(event.canBeLoggedDirectly)

        logEventInternal(
            event,
            params: params,
            analyticsSystems: analyticsSystems,
            contextParams: contextParams,
            limit: limit
        )
    }

    static func debugLog(eventInfo: any AnalyticsDebugEvent, contextParams: Analytics.ContextParams = .default) {
        logInternal(
            eventInfo.title,
            params: eventInfo.analyticsParams,
            contextParams: contextParams,
            analyticsSystems: [.crashlytics]
        )
    }

    // MARK: - Private

    fileprivate static func log(error: Error, params: [ParameterKey: String] = [:]) {
        var params = params

        switch error {
        case is WCTransactionSignError:
            params[.errorDescription] = error.localizedDescription
            let nsError = NSError(
                domain: "WalletConnect Error",
                code: 0,
                userInfo: params.dictionaryParams
            )
            Crashlytics.crashlytics().record(error: nsError)

        case let sdkError as TangemSdkError:
            params[.errorKey] = String(describing: sdkError)
            let nsError = NSError(
                domain: "Tangem SDK Error #\(sdkError.code)",
                code: sdkError.code,
                userInfo: params.dictionaryParams
            )
            Crashlytics.crashlytics().record(error: nsError)

        default:
            Crashlytics.crashlytics().record(error: error)
        }
    }

    private static func assertCanSend(event: Event, limit: EventLimit) -> Bool {
        guard limit.isLimited else {
            return true
        }

        let extraEventId = limit.extraEventId.map { "_\($0)" } ?? ""
        let eventId = event.rawValue + extraEventId

        var eventIds = analyticsContext.value(forKey: .limitedEvents, scope: limit.contextScope) as? [String] ?? []

        if eventIds.contains(eventId) {
            return false
        }

        eventIds.append(eventId)
        analyticsContext.set(value: eventIds, forKey: .limitedEvents, scope: limit.contextScope)
        return true
    }

    private static func logEventInternal(
        _ event: Event,
        params: [ParameterKey: String] = [:],
        analyticsSystems: [Analytics.AnalyticsSystem] = [.firebase, .amplitude, .crashlytics],
        contextParams: Analytics.ContextParams,
        limit: Analytics.EventLimit = .unlimited
    ) {
        if AppEnvironment.current.isXcodePreview {
            return
        }

        guard assertCanSend(event: event, limit: limit) else {
            return
        }

        logInternal(
            event.rawValue,
            params: params.dictionaryParams,
            contextParams: contextParams,
            analyticsSystems: analyticsSystems
        )
    }

    private static func logInternal(
        _ event: String,
        params: [String: Any] = [:],
        contextParams: Analytics.ContextParams,
        analyticsSystems: [Analytics.AnalyticsSystem]
    ) {
        if AppEnvironment.current.isXcodePreview {
            return
        }

        var params = params

        params.merge(contextParams.analyticsParams.dictionaryParams, uniquingKeysWith: { old, _ in old })

        for system in analyticsSystems {
            switch system {
            case .firebase:
                logFirebaseInternal(event, params: params)
            case .crashlytics:
                let message = "\(event).\(params)"
                Crashlytics.crashlytics().log(message)
            case .amplitude:
                AmplitudeWrapper.shared.track(eventType: event, eventProperties: params)
            case .appsFlyer:
                let convertedEvent = AppsFlyerAnalyticsEventConverter.convert(event: event)
                let convertedParams = AppsFlyerAnalyticsEventConverter.convert(params: params)
                AppsFlyerLib.shared().logEvent(name: convertedEvent, values: convertedParams, completionHandler: { params, error in
                    if let error {
                        AnalyticsLogger.error(params, error: error)
                    }
                })
            }
        }

        let printableParams: [String: String] = params.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) }
        if let data = try? JSONSerialization.data(withJSONObject: printableParams, options: .sortedKeys),
           let paramsString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: ",\"", with: ", \"") {
            let logMessage = "Analytics event: \(event). Params: \(paramsString)"
            AnalyticsLogger.info(logMessage)
        }
    }

    private static func logFirebaseInternal(_ event: String, params: [String: Any]) {
        // Preform logging in an asynchronous fashion due to the need for additional event mapping and processing
        firebaseLoggingQueue.async {
            let convertedEvent = FirebaseAnalyticsEventConverter.convert(event: event)
            let convertedParams = FirebaseAnalyticsEventConverter.convert(params: params)
            FirebaseAnalytics.Analytics.logEvent(convertedEvent, parameters: convertedParams)
        }
    }
}

// MARK: - Private

private extension Dictionary where Key == Analytics.ParameterKey, Value == String {
    var dictionaryParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}

private extension Analytics.Event {
    var canBeLoggedDirectly: Bool {
        switch self {
        case .toppedUp,
             .purchased:
            return false
        default:
            return true
        }
    }
}

// MARK: - Error extension

extension Analytics {
    static func error(error: Error) {
        self.error(error: error, params: [Analytics.ParameterKey: String]())
    }

    static func error(error: Error, params: [Analytics.ParameterKey: Analytics.ParameterValue]) {
        self.error(error: error, params: params.mapValues { $0.rawValue })
    }

    static func error(error: Error, params: [Analytics.ParameterKey: String]) {
        guard !error.toTangemSdkError().isUserCancelled else {
            return
        }

        Analytics.log(error: error, params: params)
    }
}
