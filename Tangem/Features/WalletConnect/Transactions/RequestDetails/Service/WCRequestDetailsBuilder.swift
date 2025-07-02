//
//  WCRequestDetailsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCRequestDetailsBuilder: Equatable {
    private let method: WalletConnectMethod
    private let source: Data

    init(method: WalletConnectMethod, source: Data) {
        self.method = method
        self.source = source
    }

    func makeRequestDetails() -> [WCTransactionDetailsSection] {
        switch method {
        case .personalSign, .solanaSignMessage, .solanaSignTransaction:
            WCSignTransactionDetailsModel(for: method, source: source).data
        case .solanaSignAllTransactions:
            WCSolanaSignAllTransactionsDetailsModel(for: method, source: source).data
        case .signTypedData, .signTypedDataV4:
            WCEthSignTypedDataDetailsModel(from: method, source: source).data
        case .sendTransaction, .signTransaction:
            WCEthTransactionDetailsModel(for: method, source: source).data
        case .bnbSign, .bnbTxConfirmation, .switchChain:
            []
        }
    }
}
