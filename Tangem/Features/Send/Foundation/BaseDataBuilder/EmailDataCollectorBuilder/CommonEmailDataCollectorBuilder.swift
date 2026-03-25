//
//  CommonEmailDataCollectorBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemStaking
import TangemFoundation
import TangemLocalization

class CommonEmailDataCollectorBuilder {
    private let walletModel: any WalletModel
    private let emailDataProvider: EmailDataProvider

    init(
        walletModel: any WalletModel,
        emailDataProvider: EmailDataProvider
    ) {
        self.walletModel = walletModel
        self.emailDataProvider = emailDataProvider
    }
}

// MARK: - EmailDataCollectorBuilder

extension CommonEmailDataCollectorBuilder: EmailDataCollectorBuilder {
    func makeMailData(transaction: BSDKTransaction, isFeeIncluded: Bool, error: SendTxError) -> EmailDataCollector {
        SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            stakingTarget: nil
        )
    }

    func makeMailData(approveTransaction: ApproveTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector {
        SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee.amount,
            destination: approveTransaction.toContractAddress,
            amount: amount,
            isFeeIncluded: isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            stakingTarget: nil
        )
    }

    func makeMailData(expressTransaction: ExpressTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector {
        SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee.amount,
            destination: expressTransaction.destinationAddress,
            amount: amount,
            isFeeIncluded: isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            stakingTarget: nil
        )
    }

    func makeMailData(
        stakingActionType: StakingAction.ActionType?,
        target: StakingTargetInfo,
        isFeeIncluded: Bool,
        amount: BSDKAmount,
        fee: BSDKFee,
        error: UniversalError
    ) -> EmailDataCollector {
        SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee.amount,
            destination: "Staking",
            amount: amount,
            isFeeIncluded: isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: stakingActionType,
            stakingTarget: target
        )
    }

    func makeMailData(
        action: StakingTransactionAction,
        stakingActionType: StakingAction.ActionType?,
        target: StakingTargetInfo,
        isFeeIncluded: Bool,
        error: SendTxError
    ) -> EmailDataCollector {
        let feeValue = action.transactions.reduce(0) { $0 + $1.fee }
        let fee = Amount(with: walletModel.feeTokenItem.blockchain, type: walletModel.feeTokenItem.amountType, value: feeValue)
        let amount = Amount(with: walletModel.tokenItem.blockchain, type: walletModel.tokenItem.amountType, value: action.amount)

        return SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee,
            destination: "Staking",
            amount: amount,
            isFeeIncluded: isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: stakingActionType,
            stakingTarget: target
        )
    }
}
