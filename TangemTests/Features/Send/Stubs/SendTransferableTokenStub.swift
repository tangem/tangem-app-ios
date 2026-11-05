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

    private let dispatcherProvider: any TransactionDispatcherProvider

    init(
        blockchain: Blockchain,
        transactionValidator: SendTransactionValidator = SendTransactionValidatorStub(),
        transactionCreator: SendTransactionCreator = SendTransactionCreatorStub(),
        tokenFeeProvidersManager: TokenFeeProvidersManager,
        transactionDispatcherProvider: any TransactionDispatcherProvider = TransactionDispatcherProviderStub()
    ) {
        self.transactionValidator = transactionValidator
        self.transactionCreator = transactionCreator
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        dispatcherProvider = transactionDispatcherProvider
        super.init(blockchain: blockchain)
    }

    override var transactionDispatcherProvider: any TransactionDispatcherProvider {
        dispatcherProvider
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
