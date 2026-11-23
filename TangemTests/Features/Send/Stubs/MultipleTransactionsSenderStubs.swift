//
//  MultipleTransactionsSenderStubs.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import BlockchainSdk

final class MultipleTransactionsSenderSpy: MultipleTransactionsSender {
    private let calls = OSAllocatedUnfairLock(initialState: [[Transaction]]())
    private let result: Result<[TransactionSendResult], SendTxError>

    var sendCalls: [[Transaction]] {
        calls.withLock { $0 }
    }

    init(result: Result<[TransactionSendResult], SendTxError>) {
        self.result = result
    }

    func send(_ transactions: [Transaction], signer: TransactionSigner) -> AnyPublisher<[TransactionSendResult], SendTxError> {
        calls.withLock { $0.append(transactions) }
        return result.publisher.eraseToAnyPublisher()
    }
}

final class WalletTransactionCreatorStub: TransactionCreator {
    var wallet: Wallet
    private let validationError: Error?

    init(blockchain: Blockchain, validationError: Error? = nil) {
        wallet = Wallet(
            blockchain: blockchain,
            publicKey: .init(seedKey: Data(), derivationType: .none),
            addressesProvider: EmptyAddressesProvider()
        )
        self.validationError = validationError
    }

    var walletPublisher: AnyPublisher<Wallet, Never> {
        Just(wallet).eraseToAnyPublisher()
    }

    func validate(amount: Amount, fee: Fee) throws {}

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        if let validationError {
            throw validationError
        }
    }
}
