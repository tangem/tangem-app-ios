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

typealias MailData = (dataCollector: EmailDataCollector, recipient: String)

protocol SendMailDataBuilder {
    // Send transaction methods
    func makeMailData(transaction: BSDKTransaction, error: SendTxError) throws -> MailData
    func makeMailData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> MailData
    func makeMailData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> MailData

    // Staking transaction methods
    func makeMailData(stakingRequestError error: UniversalError) throws -> MailData
    func makeMailData(action: StakingTransactionAction, error: SendTxError) throws -> MailData
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
