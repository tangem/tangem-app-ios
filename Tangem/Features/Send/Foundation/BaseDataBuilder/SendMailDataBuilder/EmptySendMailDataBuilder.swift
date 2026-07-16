//
//  EmptySendMailDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemStaking

struct EmptySendMailDataBuilder: SendMailDataBuilder {
    // MARK: - Send transaction methods

    func makeSupportData(transaction: BSDKTransaction, error: SendTxError) throws -> SupportData {
        throw SendMailDataBuilderError.notSupported
    }

    func makeSupportData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> SupportData {
        throw SendMailDataBuilderError.notSupported
    }

    func makeSupportData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> SupportData {
        throw SendMailDataBuilderError.notSupported
    }

    // MARK: - Staking transaction methods

    func makeSupportData(stakingRequestError error: UniversalError) throws -> SupportData {
        throw SendMailDataBuilderError.notSupported
    }

    func makeSupportData(action: StakingTransactionAction, error: SendTxError) throws -> SupportData {
        throw SendMailDataBuilderError.notSupported
    }
}
