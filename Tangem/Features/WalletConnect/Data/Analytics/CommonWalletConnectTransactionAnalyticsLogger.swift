//
//  CommonWalletConnectTransactionAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class CommonWalletConnectTransactionAnalyticsLogger: WalletConnectTransactionAnalyticsLogger {
    func logSignatureRequestReceived(transactionData: WCHandleTransactionData, simulationState: TransactionSimulationState) {
        let emulationStatus: Analytics.ParameterValue
        let simulationResult = getSimulationResult(from: simulationState)

        switch simulationState {
        case .loading:
            assertionFailure("Invalid simulation state. Developer mistake.")
            return
        case .simulationNotSupported:
            emulationStatus = .walletConnectTransactionEmulationStatusCantEmulate
        case .simulationFailed:
            emulationStatus = .error
        case .simulationSucceeded:
            emulationStatus = .walletConnectTransactionEmulationStatusEmulated
        }

        let signatureRequestReceivedEvent = Analytics.Event.walletConnectSignatureRequestReceived
        let signatureRequestReceivedParams: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .blockchain: transactionData.blockchain.displayName,
            .walletConnectTransactionEmulationStatus: emulationStatus.rawValue,
            .type: simulationResult.rawValue,
        ]

        Analytics.log(event: signatureRequestReceivedEvent, params: signatureRequestReceivedParams)
    }

    func logSignatureRequestHandled(transactionData: WCHandleTransactionData, simulationState: TransactionSimulationState) {
        let event = Analytics.Event.walletConnectSignatureRequestHandled
        let simulationResult = getSimulationResult(from: simulationState)

        let params: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .blockchain: transactionData.blockchain.displayName,
            .type: simulationResult.rawValue,
        ]

        Analytics.log(event: event, params: params)
    }

    func logSignatureRequestFailed(transactionData: WCHandleTransactionData, error: some Error) {
        let event = Analytics.Event.walletConnectSignatureRequestFailed
        let params: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .blockchain: transactionData.blockchain.displayName,
            .errorCode: "\(error.universalErrorCode)",
            .errorDescription: error.localizedDescription,
        ]

        Analytics.log(event: event, params: params)
    }

    func logTransactionDetailsOpened(transactionData: WCHandleTransactionData) {
        let event = Analytics.Event.walletConnectTransactionDetailsOpened
        let params: [Analytics.ParameterKey: String] = [
            .methodName: transactionData.method.rawValue,
            .walletConnectDAppName: transactionData.dAppData.name,
            .walletConnectDAppUrl: transactionData.dAppData.domain.absoluteString,
            .blockchain: transactionData.blockchain.displayName,
        ]

        Analytics.log(event: event, params: params)
    }

    func logSignButtonTapped(transactionData: WCHandleTransactionData) {
        Analytics.log(event: .walletConnectTransactionSignButtonTapped, params: [.methodName: transactionData.method.rawValue])
    }

    func logCancelButtonTapped() {
        Analytics.log(.walletConnectCancelButtonTapped, params: [.type: .sign])
    }

    private func getSimulationResult(from simulationState: TransactionSimulationState) -> Analytics.ParameterValue {
        if case .simulationSucceeded(let result) = simulationState {
            return result.validationStatus?.analyticsTypeValue ?? .unknown
        }

        return .unknown
    }
}

private extension BlockaidChainScanResult.ValidationStatus {
    var analyticsTypeValue: Analytics.ParameterValue {
        switch self {
        case .malicious, .warning:
            Analytics.ParameterValue.walletConnectRisky
        case .benign:
            Analytics.ParameterValue.walletConnectVerified
        }
    }
}
