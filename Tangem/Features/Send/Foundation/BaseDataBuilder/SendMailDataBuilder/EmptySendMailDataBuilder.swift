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

    func makeMailData(transaction: BSDKTransaction, error: SendTxError) throws -> MailData {
        throw SendMailDataBuilderError.notSupported
    }

    func makeMailData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> MailData {
        throw SendMailDataBuilderError.notSupported
    }

    func makeMailData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> MailData {
        throw SendMailDataBuilderError.notSupported
    }

    // MARK: - Staking transaction methods

    func makeMailData(stakingRequestError error: UniversalError) throws -> MailData {
        throw SendMailDataBuilderError.notSupported
    }

    func makeMailData(action: StakingTransactionAction, error: SendTxError) throws -> MailData {
        throw SendMailDataBuilderError.notSupported
    }
}
