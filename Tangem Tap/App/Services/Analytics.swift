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
import TangemSdk

class Analytics {
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
        
        fileprivate static var nfcError: String {
            "nfc_error"
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
    }
    
    static func log(event: Event, parameters: [String: Any]? = nil) {
        FirebaseAnalytics.Analytics.logEvent(event.rawValue, parameters: parameters)
    }
    
    static func logScan(card: Card) {
        let blockchainName = card.cardData?.blockchainName ?? ""
        
        let params = collectCardData(card, additionalParams: [.blockchain: blockchainName])
        FirebaseAnalytics.Analytics.logEvent(Event.cardIsScanned.rawValue, parameters: params.firebaseParams)
        Crashlytics.crashlytics().setCustomValue(blockchainName, forKey: ParameterKey.blockchain.rawValue)
    }
    
    static func logTx(blockchainName: String?, isPushed: Bool = false) {
        FirebaseAnalytics.Analytics.logEvent(isPushed ? Event.transactionIsPushed.rawValue : Event.transactionIsSent.rawValue,
                                             parameters: [ParameterKey.blockchain.rawValue: blockchainName ?? ""])
    }
    
    static func logCardSdkError(_ error: TangemSdkError, for action: Action, parameters: [ParameterKey: Any] = [:]) {
        if case .userCancelled = error { return }
        
        var params = parameters
        params[.action] = action.rawValue
        params[.errorKey] = String(describing: error)
        
        let nsError = NSError(domain: "Tangem SDK Error #\(error.code)", code: error.code, userInfo: params.firebaseParams)
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    static func logCardSdkError(_ error: TangemSdkError, for action: Action, card: Card, parameters: [ParameterKey: Any] = [:]) {
        let params = collectCardData(card, additionalParams: parameters)
        
        logCardSdkError(error, for: action, parameters: params)
    }
    
    static func log(error: Error) {
        if case .userCancelled = error.toTangemSdkError() {
            return
        }

        Crashlytics.crashlytics().record(error: error)
    }
    
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
        FirebaseAnalytics.Analytics.logEvent(firEvent.rawValue, parameters: params.firebaseParams)
    }
    
    private static func collectCardData(_ card: Card, additionalParams: [ParameterKey: Any] = [:]) -> [ParameterKey: Any] {
        var params = additionalParams
        params[.batchId] = card.cardData?.batchId ?? ""
        params[.firmware] = card.firmwareVersionString
        return params
    }
}

fileprivate extension Dictionary where Key == Analytics.ParameterKey, Value == Any {
    var firebaseParams: [String: Any] {
        var convertedParams = [String:Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}

extension Analytics {
    enum WalletConnectEvent {
        enum SessionEvent {
            case disconnect, connect
        }
        
        case error(Error, WalletConnectAction?), session(SessionEvent, URL), action(WalletConnectAction), invalidRequest(json: String?)
    }
}
