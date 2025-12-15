//
//  ExpressTransactionProcessorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressTransactionProcessorFactory {
    let walletModel: any WalletModel
    let transactionDispatcher: any TransactionDispatcher

    func makeCEXTransactionProcessor() throws -> ExpressCEXTransactionProcessor {
        CommonExpressCEXTransactionProcessor(
            tokenItem: walletModel.tokenItem,
            transactionCreator: walletModel.transactionCreator,
            transactionDispatcher: transactionDispatcher
        )
    }

    func makeDEXTransactionProcessor() throws -> ExpressDEXTransactionProcessor {
        switch walletModel.tokenItem.blockchain {
        case let blockchain where blockchain.isEvm:
            return EVMExpressDEXTransactionProcessor(
                feeTokenItem: walletModel.feeTokenItem,
                transactionCreator: walletModel.transactionCreator,
                transactionDispatcher: transactionDispatcher
            )
        case .solana:
            return SolanaExpressDEXTransactionProcessor(
                transactionDispatcher: transactionDispatcher
            )
        case let blockchain:
            throw Error.dexNotSupported(blockchain: blockchain.displayName)
        }
    }

    func makeExpressApproveTransactionProcessor() -> ExpressApproveTransactionProcessor {
        CommonExpressApproveTransactionProcessor(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            transactionCreator: walletModel.transactionCreator,
            transactionDispatcher: transactionDispatcher
        )
    }
}

extension ExpressTransactionProcessorFactory {
    enum Error: LocalizedError {
        case dexNotSupported(blockchain: String)

        var errorDescription: String? {
            switch self {
            case .dexNotSupported(let blockchain): "DEX is not supported for \(blockchain)"
            }
        }
    }
}
