//
//  EmailDataCollectorBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemStaking
import TangemFoundation

protocol EmailDataCollectorBuilder {
    func makeMailData(transaction: BSDKTransaction, isFeeIncluded: Bool, error: SendTxError) -> EmailDataCollector

    func makeMailData(approveTransaction: ApproveTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector

    func makeMailData(expressTransaction: ExpressTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector

    func makeMailData(
        stakingActionType: StakingAction.ActionType?,
        target: StakingTargetInfo,
        isFeeIncluded: Bool,
        amount: BSDKAmount,
        fee: BSDKFee,
        error: UniversalError
    ) -> EmailDataCollector

    func makeMailData(
        action: StakingTransactionAction,
        stakingActionType: StakingAction.ActionType?,
        target: StakingTargetInfo,
        isFeeIncluded: Bool,
        error: SendTxError
    ) -> EmailDataCollector
}
