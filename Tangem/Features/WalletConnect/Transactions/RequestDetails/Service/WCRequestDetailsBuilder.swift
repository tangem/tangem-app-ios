//
//  WCRequestDetailsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct WCRequestDetailsBuilder: Equatable {
    private let method: WalletConnectMethod
    private let source: Data
    private let blockchain: Blockchain
    private let simulationResult: BlockaidChainScanResult?

    init(method: WalletConnectMethod, source: Data, blockchain: Blockchain, simulationResult: BlockaidChainScanResult? = nil) {
        self.method = method
        self.source = source
        self.blockchain = blockchain
        self.simulationResult = simulationResult
    }

    func makeRequestDetails() -> [WCTransactionDetailsSection] {
        switch method {
        case .personalSign, .solanaSignMessage, .solanaSignTransaction, .addChain, .signMessage:
            WCSignTransactionDetailsModel(for: method, source: source).data
        case .solanaSignAllTransactions:
            WCSolanaSignAllTransactionsDetailsModel(for: method, source: source).data
        case .signTypedData, .signTypedDataV4:
            WCEthSignTypedDataDetailsModel(from: method, source: source).data
        case .sendTransaction, .signTransaction:
            WCEthTransactionDetailsModel(for: method, source: source, blockchain: blockchain).data
        case .bnbSign, .bnbTxConfirmation, .switchChain:
            []
        case .sendTransfer, .getAccountAddresses, .signPsbt:
            []
        }
    }
}
