//
//  TangemPayRecentOperationsRecorder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TangemPayRecentOperationsRecorder {
    private let store: TangemPayRecentOperationsStore
    private let customerWalletId: String

    init(store: TangemPayRecentOperationsStore, customerWalletId: String) {
        self.store = store
        self.customerWalletId = customerWalletId
    }

    func record(_ transaction: SwapFlowConfiguration.SwapSentTransaction) {
        guard let operation = makeOperation(from: transaction) else {
            return
        }

        store.record(operation, customerWalletId: customerWalletId)
    }
}

// MARK: - Private

private extension TangemPayRecentOperationsRecorder {
    func makeOperation(from transaction: SwapFlowConfiguration.SwapSentTransaction) -> TangemPayRecentOperation? {
        guard let receive = transaction.receive as? SendSourceToken else {
            return nil
        }

        let from = side(of: transaction.source)
        let to = side(of: receive)

        guard from.isPaymentAccount != to.isPaymentAccount else {
            return nil
        }

        return TangemPayRecentOperation(from: from, to: to, date: Date())
    }

    func side(of token: SendSourceToken) -> TangemPayRecentOperation.Side {
        TangemPayRecentOperation.Side(
            userWalletId: token.userWalletInfo.id.stringValue,
            tokenItem: token.tokenItem,
            isPaymentAccount: token.isTangemPayAccount
        )
    }
}
