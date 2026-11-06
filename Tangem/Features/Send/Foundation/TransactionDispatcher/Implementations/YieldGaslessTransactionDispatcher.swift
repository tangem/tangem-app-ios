//
//  YieldGaslessTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class YieldGaslessTransactionDispatcher {
    private let walletModel: any WalletModel
    private let gaslessTransactionSender: any GaslessBatchTransactionSending
    private let logger: YieldAnalyticsLogger

    init(
        walletModel: any WalletModel,
        gaslessTransactionSender: any GaslessBatchTransactionSending,
        logger: YieldAnalyticsLogger
    ) {
        self.walletModel = walletModel
        self.gaslessTransactionSender = gaslessTransactionSender
        self.logger = logger
    }
}

// MARK: - GaslessBatchTransactionSending

extension YieldGaslessTransactionDispatcher: GaslessBatchTransactionSending {
    func send(batch transactions: [BSDKTransaction], fee: BSDKFee) async throws -> TransactionDispatcherResult {
        guard let firstTransaction = transactions.first else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let result: TransactionDispatcherResult

        do {
            result = try await gaslessTransactionSender.send(batch: transactions, fee: fee)
        } catch {
            AppLogger.error(error: error)
            throw TransactionDispatcherResultMapper().mapError(error.toUniversalError(), transaction: .transfer(firstTransaction))
        }

        if let feeToken = fee.amount.type.token {
            logger.logTransactionSent(with: result, feeTokenItem: .token(feeToken, walletModel.tokenItem.blockchainNetwork))
        }

        await refreshYieldModuleVersionIfUpgraded(fee: fee)

        return result
    }
}

// MARK: - Private

private extension YieldGaslessTransactionDispatcher {
    func refreshYieldModuleVersionIfUpgraded(fee: BSDKFee) async {
        guard let yieldWithdraw = (fee.parameters as? EthereumGaslessTransactionFeeParameters)?.yieldWithdraw,
              yieldWithdraw.upgrade.isRequired else {
            return
        }

        do {
            try await walletModel.yieldModuleManager?.versionChecker?.refreshStoredVersion(
                userModuleAddress: yieldWithdraw.yieldContractAddress
            )
        } catch {
            AppLogger.error(error: error)
        }
    }
}
