//
//  SendTransferableTokenStub.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
@testable import Tangem

// MARK: - SendTransferableToken

final class SendTransferableTokenStub: SendSourceTokenStub, SendTransferableToken {
    let transactionValidator: SendTransactionValidator
    let transactionCreator: SendTransactionCreator
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    private let balanceProvider: TokenBalanceProvider?
    private let dispatcherProvider: any TransactionDispatcherProvider

    init(
        blockchain: Blockchain,
        transactionValidator: SendTransactionValidator = SendTransactionValidatorStub(),
        transactionCreator: SendTransactionCreator = SendTransactionCreatorStub(),
        tokenFeeProvidersManager: TokenFeeProvidersManager,
        balance: Decimal? = nil,
        balanceProvider: TokenBalanceProvider? = nil,
        transactionDispatcherProvider: any TransactionDispatcherProvider = TransactionDispatcherProviderStub()
    ) {
        self.transactionValidator = transactionValidator
        self.transactionCreator = transactionCreator
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        self.balanceProvider = balanceProvider ?? balance.map {
            TokenBalanceProviderStub(balanceType: .loaded($0), formattedBalanceType: .loaded("\($0)"))
        }
        dispatcherProvider = transactionDispatcherProvider
        super.init(blockchain: blockchain)
    }

    override var availableBalanceProvider: TokenBalanceProvider {
        balanceProvider ?? super.availableBalanceProvider
    }

    override var transactionDispatcherProvider: any TransactionDispatcherProvider {
        dispatcherProvider
    }
}

// MARK: - ControllableTokenBalanceProviderStub

final class ControllableTokenBalanceProviderStub: TokenBalanceProvider {
    private let subject: CurrentValueSubject<Decimal, Never>

    init(balance: Decimal) {
        subject = CurrentValueSubject(balance)
    }

    var balanceType: TokenBalanceType { .loaded(subject.value) }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { subject.map { .loaded($0) }.eraseToAnyPublisher() }
    var formattedBalanceType: FormattedTokenBalanceType { .loaded("\(subject.value)") }
    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { subject.map { .loaded("\($0)") }.eraseToAnyPublisher() }

    func set(balance: Decimal) {
        subject.send(balance)
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

struct BuildingTransactionCreatorStub: SendTransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: "",
            destinationAddress: destinationAddress,
            changeAddress: "",
            contractAddress: nil,
            params: params
        )
    }
}
