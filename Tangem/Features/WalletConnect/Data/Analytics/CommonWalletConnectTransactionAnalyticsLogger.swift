//
//  CommonWalletConnectTransactionAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class CommonWalletConnectTransactionAnalyticsLogger: WalletConnectTransactionAnalyticsLogger {
    func logSignatureRequestReceived(transactionData: WCHandleTransactionData, simulationState: TransactionSimulationState) {
        let securityAlertEvent: Analytics.Event?
        let securityAlertParamKey: Analytics.ParameterKey?
        let securityAlertParamValue: Analytics.ParameterValue?
        let emulationStatus: Analytics.ParameterValue

        switch simulationState {
        case .notStarted, .loading:
            assertionFailure("Invalid simulation state. Developer mistake.")
            return
        case .simulationNotSupported:
            securityAlertEvent = nil
            securityAlertParamKey = nil
            securityAlertParamValue = nil
            emulationStatus = .walletConnectTransactionEmulationStatusCantEmulate
        case .simulationFailed:
            securityAlertEvent = nil
            securityAlertParamKey = nil
            securityAlertParamValue = nil
            emulationStatus = .error
        case .simulationSucceeded(let scanResult):
            emulationStatus = .walletConnectTransactionEmulationStatusEmulated

            switch scanResult.validationStatus {
            case .malicious, .warning:
                securityAlertEvent = .walletConnectSecurityAlertShown
                securityAlertParamKey = .commonType
                securityAlertParamValue = .walletConnectSecurityAlertRisky
            case .benign:
                securityAlertEvent = nil
                securityAlertParamKey = nil
                securityAlertParamValue = nil
            case nil:
                securityAlertEvent = .walletConnectSecurityAlertShown
                securityAlertParamKey = .commonType
                securityAlertParamValue = .unknown
            }
        }

        let signatureRequestReceivedEvent = Analytics.Event.walletConnectSignatureRequestReceived
        let signatureRequestReceivedParams: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .walletConnectBlockchain: transactionData.blockchain.displayName,
            .walletConnectTransactionEmulationStatus: emulationStatus.rawValue,
        ]

        Analytics.log(event: signatureRequestReceivedEvent, params: signatureRequestReceivedParams)

        guard let securityAlertEvent, let securityAlertParamKey, let securityAlertParamValue else { return }

        let securityAlertParams: [Analytics.ParameterKey: String] = [
            securityAlertParamKey: securityAlertParamValue.rawValue,
            .source: Analytics.ParameterValue.walletConnectSecurityAlertSourceSmartContract.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
        ]

        Analytics.log(event: securityAlertEvent, params: securityAlertParams)
    }

    func logSignatureRequestHandled(transactionData: WCHandleTransactionData) {
        let event = Analytics.Event.walletConnectSignatureRequestHandled
        let params: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .walletConnectBlockchain: transactionData.blockchain.displayName,
        ]

        Analytics.log(event: event, params: params)
    }

    func logSignatureRequestFailed(transactionData: WCHandleTransactionData, error: some Error) {
        let event = Analytics.Event.walletConnectSignatureRequestFailed
        let params: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .walletConnectBlockchain: transactionData.blockchain.displayName,
            .errorCode: "\(error.universalErrorCode)",
        ]

        Analytics.log(event: event, params: params)
    }

    func logTransactionDetailsOpened(transactionData: WCHandleTransactionData) {
        let event = Analytics.Event.walletConnectTransactionDetailsOpened
        let params: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .walletConnectBlockchain: transactionData.blockchain.displayName,
        ]

        Analytics.log(event: event, params: params)
    }

    func logSignButtonTapped(transactionData: WCHandleTransactionData) {
        Analytics.log(event: .walletConnectTransactionSignButtonTapped, params: [.methodName: transactionData.method.rawValue])
    }

    func logCancelButtonTapped() {
        Analytics.log(.walletConnectCancelButtonTapped, params: [.type: .sign])
    }
}
