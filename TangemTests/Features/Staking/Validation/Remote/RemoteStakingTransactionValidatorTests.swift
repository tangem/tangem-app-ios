//
//  RemoteStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import BlockchainSdk
@testable import Tangem

@Suite("RemoteStakingTransactionValidator Tests")
struct RemoteStakingTransactionValidatorTests {
    typealias SUT = RemoteStakingTransactionValidator

    // MARK: - Transaction Processing

    @Test
    func singleTransactionCallsVerifier() async throws {
        let spy = BlockaidStakingVerifierSpy()
        let sut = makeSUT(verifier: spy)

        try await sut.validate([sampleTransaction])

        #expect(spy.verifyCallCount == 1)
        #expect(spy.lastUnsignedTransaction == sampleTransaction)
    }

    @Test
    func multipleTransactionsAllVerified() async throws {
        let spy = BlockaidStakingVerifierSpy()
        let sut = makeSUT(verifier: spy)

        try await sut.validate(multipleTransactions)

        #expect(spy.verifyCallCount == 3)
        #expect(spy.allUnsignedTransactions == multipleTransactions)
    }

    @Test
    func emptyArraySkipsVerifier() async throws {
        let spy = BlockaidStakingVerifierSpy()
        let sut = makeSUT(verifier: spy)

        try await sut.validate([])

        #expect(spy.verifyCallCount == 0)
    }

    // MARK: - Success Path

    @Test
    func benignResponsePassesValidation() async throws {
        let stub = BlockaidStakingVerifierSuccessStub()
        let sut = makeSUT(verifier: stub)

        try await sut.validate([sampleTransaction])
    }

    // MARK: - Error Propagation

    @Test(arguments: errorCases)
    func verifierErrorPropagates(error: RemoteStakingValidationError) async {
        let stub = BlockaidStakingVerifierErrorStub(error: error)
        let sut = makeSUT(verifier: stub)

        await #expect(throws: error) {
            try await sut.validate([sampleTransaction])
        }
    }

    @Test
    func verifierStopsOnFirstError() async throws {
        let spy = BlockaidStakingVerifierSpy(failOnCall: 2)
        let sut = makeSUT(verifier: spy)

        await #expect(throws: RemoteStakingValidationError.self) {
            try await sut.validate(multipleTransactions)
        }

        #expect(spy.verifyCallCount == 2)
    }
}

// MARK: - Test Data

private extension RemoteStakingTransactionValidatorTests {
    var sampleTransaction: String { "sample_staking_tx" }
    var multipleTransactions: [String] { ["tx_1", "tx_2", "tx_3"] }
    static let defaultAccountAddress = "0x1234567890123456789012345678901234567890"

    static let errorCases: [RemoteStakingValidationError] = [
        .warning(description: "Suspicious transaction"),
        .malicious(description: "Malicious contract"),
        .validationFailed(description: "Network error"),
    ]
}

// MARK: - SUT Factory

private extension RemoteStakingTransactionValidatorTests {
    func makeSUT(
        network: BlockaidSupportedNetwork = .evm(.ethereum(testnet: false)),
        accountAddress: String = defaultAccountAddress,
        verifier: BlockaidStakingVerifier
    ) -> SUT {
        SUT(network: network, accountAddress: accountAddress, verifier: verifier)
    }
}

// MARK: - Test Doubles

private final class BlockaidStakingVerifierSpy: BlockaidStakingVerifier, @unchecked Sendable {
    private(set) var verifyCallCount = 0
    private(set) var lastUnsignedTransaction: String?
    private(set) var allUnsignedTransactions: [String] = []
    private let failOnCall: Int?

    init(failOnCall: Int? = nil) {
        self.failOnCall = failOnCall
    }

    func verify(
        network: BlockaidSupportedNetwork,
        accountAddress: String,
        unsignedTransaction: String
    ) async throws {
        verifyCallCount += 1
        lastUnsignedTransaction = unsignedTransaction
        allUnsignedTransactions.append(unsignedTransaction)

        if let failOnCall, verifyCallCount == failOnCall {
            throw RemoteStakingValidationError.validationFailed(description: "Test error")
        }
    }
}

private struct BlockaidStakingVerifierErrorStub: BlockaidStakingVerifier {
    let error: RemoteStakingValidationError

    func verify(
        network: BlockaidSupportedNetwork,
        accountAddress: String,
        unsignedTransaction: String
    ) async throws {
        throw error
    }
}

private struct BlockaidStakingVerifierSuccessStub: BlockaidStakingVerifier {
    func verify(
        network: BlockaidSupportedNetwork,
        accountAddress: String,
        unsignedTransaction: String
    ) async throws {}
}
