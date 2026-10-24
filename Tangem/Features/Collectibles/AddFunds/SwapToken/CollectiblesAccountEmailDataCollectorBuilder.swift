//
//  CollectiblesAccountEmailDataCollectorBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemExpress
import TangemFoundation
import TangemStaking

struct CollectiblesAccountEmailDataCollectorBuilder: EmailDataCollectorBuilder {
    func makeMailData(transaction: BSDKTransaction, isFeeIncluded: Bool, error: SendTxError) -> EmailDataCollector {
        BaseDataCollector()
    }

    func makeMailData(approveTransaction: ApproveTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector {
        BaseDataCollector()
    }

    func makeMailData(expressTransaction: ExpressTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector {
        BaseDataCollector()
    }

    func makeMailData(
        stakingActionType: StakingAction.ActionType?,
        target: StakingTargetInfo,
        isFeeIncluded: Bool,
        amount: BSDKAmount,
        fee: BSDKFee,
        error: UniversalError
    ) -> EmailDataCollector {
        BaseDataCollector()
    }

    func makeMailData(
        action: StakingTransactionAction,
        stakingActionType: StakingAction.ActionType?,
        target: StakingTargetInfo,
        isFeeIncluded: Bool,
        error: SendTxError
    ) -> EmailDataCollector {
        BaseDataCollector()
    }
}
