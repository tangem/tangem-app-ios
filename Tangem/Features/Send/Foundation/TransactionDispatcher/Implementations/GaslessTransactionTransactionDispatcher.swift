//
//  GaslessTransactionTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GaslessTransactionBuilder {
    private let walletModel: any WalletModel

    func getEIP7702SignedData() {}
}

// final class GaslessTransactionBuilder {
//    typealias MetaTransaction = GaslessTransactionsDTO.Request.MetaTransaction
//
//    private let walletModel: any WalletModel
//    private let transactionSigner: TangemSigner
//
//    init(walletModel: any WalletModel, transactionSigner: TangemSigner) {
//        self.walletModel = walletModel
//        self.transactionSigner = transactionSigner
//    }
//
//    func buildMetaTransaction(inputTransaction: Transaction) -> GaslessTransactionsDTO.Request.MetaTransaction {
//        guard let gaslessDataProvider = walletModel.gas
//
//        walletModel.wa
//
////        let transaction: MetaTransaction.GaslessTransaction.Transaction = .init(
////            to: inputTransaction.destinationAddress,
////            value: "0",
////            data: inputTransaction.da
////        )
//    }
// }
//
// final class GaslessTransactionTransactionDispatcher {
////    private let sendDispatcher: TransactionDispatcher
// }
//
//// extension GaslessTransactionTransactionDispatcher: TransactionDispatcher {}
