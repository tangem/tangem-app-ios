//
//  WalletConnectTransactionAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectTransactionAnalyticsLogger {
    func logSignatureRequestReceived(transactionData: WCHandleTransactionData, simulationState: TransactionSimulationState)
    func logSignatureRequestHandled(transactionData: WCHandleTransactionData)
    func logSignatureRequestFailed(transactionData: WCHandleTransactionData, error: some Error)
    func logTransactionDetailsOpened(transactionData: WCHandleTransactionData)
    func logSignButtonTapped(transactionData: WCHandleTransactionData)
    func logCancelButtonTapped()
}
