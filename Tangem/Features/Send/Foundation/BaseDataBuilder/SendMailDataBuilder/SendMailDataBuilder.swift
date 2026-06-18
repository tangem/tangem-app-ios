//
//  SendMailDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemStaking
import TangemFoundation

typealias SupportData = (emailDataCollector: EmailDataCollector, chatDataCollector: ChatDataCollector, recipient: String)

protocol SendMailDataBuilder {
    // Send transaction methods
    func makeSupportData(transaction: BSDKTransaction, error: SendTxError) throws -> SupportData
    func makeSupportData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> SupportData
    func makeSupportData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> SupportData

    // Staking transaction methods
    func makeSupportData(stakingRequestError error: UniversalError) throws -> SupportData
    func makeSupportData(action: StakingTransactionAction, error: SendTxError) throws -> SupportData
}

enum SendMailDataBuilderError: LocalizedError {
    case notFound(String)
    case notSupported

    var errorDescription: String? {
        switch self {
        case .notFound(let string): "\(string) not found"
        case .notSupported: "Mail data builder not supported"
        }
    }
}
