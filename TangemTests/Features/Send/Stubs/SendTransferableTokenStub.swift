//
//  SendTransferableTokenStub.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
@testable import Tangem

// MARK: - SendTransferableToken

final class SendTransferableTokenStub: SendSourceTokenStub, SendTransferableToken {
    let transactionValidator: SendTransactionValidator
    let transactionCreator: SendTransactionCreator
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    init(
        blockchain: Blockchain,
        transactionValidator: SendTransactionValidator = SendTransactionValidatorStub(),
        tokenFeeProvidersManager: TokenFeeProvidersManager
    ) {
        self.transactionValidator = transactionValidator
        transactionCreator = SendTransactionCreatorStub()
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        super.init(blockchain: blockchain)
    }
}

// MARK: - SendTransactionValidator

struct SendTransactionValidatorStub: SendTransactionValidator {
    var validateError: Error?

    func validate(amount: Amount) throws {}

    func validate(amount: Amount, fee: Fee) throws {
        if let validateError {
            throw validateError
        }
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {}
}

// MARK: - SendTransactionCreator

struct SendTransactionCreatorStub: SendTransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        throw NSError(domain: "SendTransactionCreatorStub", code: 0)
    }
}
