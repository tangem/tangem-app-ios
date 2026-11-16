//
//  LendingDepositPreparationFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

protocol LendingDepositPreparationMaking {
    func make(_ preparation: LendingDepositPreparation, yieldModule: String) -> TransferPreparation?
}

struct LendingDepositPreparationFactory: LendingDepositPreparationMaking {
    let walletModel: any WalletModel
    let signerFactory: TangemSignerFactory
    let reader: LendingModuleReader
    var wrappedNative: String = LendingOnAave.wrappedNativeAddress

    func make(_ preparation: LendingDepositPreparation, yieldModule: String) -> TransferPreparation? {
        guard let transactionsSender = walletModel.multipleTransactionsSender,
              let networkProvider = walletModel.ethereumNetworkProvider,
              let factory = try? reader.factoryAddress() else {
            return nil
        }

        let owner = walletModel.defaultAddressString
        let blockchain = walletModel.tokenItem.blockchain
        let call = YieldLendingTransactionProvider.preparationCall(
            preparation,
            owner: owner,
            yieldModule: yieldModule,
            wrappedNative: wrappedNative,
            factory: factory
        )

        return LendingDepositPreparationSender(
            preparationCall: TransferPreparationCall(destination: call.destination, value: 0, data: call.data),
            blockchain: blockchain,
            isDemo: walletModel.isDemo,
            transactionCreator: walletModel.transactionCreator,
            transactionsSender: transactionsSender,
            signer: signerFactory.makeSigner(),
            gasEstimator: LendingDepositGasEstimator(
                owner: owner,
                blockchain: blockchain,
                simulator: BlockaidLendingDepositGasSimulator(),
                allowsFallback: preparation != .deployModule
            ),
            hasPendingTransactions: {
                async let pendingCount = networkProvider.getPendingTxCount(owner).async()
                async let confirmedCount = networkProvider.getTxCount(owner).async()
                let pending = try await pendingCount
                let confirmed = try await confirmedCount
                return pending > confirmed
            },
            onSent: { [walletModel] in walletModel.updateAfterSendingTransaction() }
        )
    }
}
