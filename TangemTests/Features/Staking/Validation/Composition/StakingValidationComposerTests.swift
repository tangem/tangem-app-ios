//
//  StakingValidationComposerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("StakingValidationComposer Tests")
struct StakingValidationComposerTests {
    typealias SUT = StakingValidationComposer

    // MARK: - Both Validators Present

    @Test
    func bothValidatorsCalledInSequence() async throws {
        let localSpy = ComposerValidatorSpy()
        let remoteSpy = ComposerValidatorSpy()
        let sut = SUT(localValidator: localSpy, remoteValidator: remoteSpy)

        try await sut.validate(sampleTransactions)

        #expect(localSpy.validateCallCount == 1)
        #expect(remoteSpy.validateCallCount == 1)
        #expect(localSpy.lastTransactions == sampleTransactions)
        #expect(remoteSpy.lastTransactions == sampleTransactions)
    }

    @Test
    func localErrorStopsExecution() async {
        let localStub = ComposerValidatorErrorStub(error: StakingTransactionValidationError.emptyOrMalformedData)
        let remoteSpy = ComposerValidatorSpy()
        let sut = SUT(localValidator: localStub, remoteValidator: remoteSpy)

        await #expect(throws: StakingTransactionValidationError.emptyOrMalformedData) {
            try await sut.validate([sampleTransaction])
        }

        #expect(remoteSpy.validateCallCount == 0)
    }

    @Test
    func remoteErrorPropagates() async {
        let localSpy = ComposerValidatorSpy()
        let remoteStub = ComposerValidatorErrorStub(error: maliciousError)
        let sut = SUT(localValidator: localSpy, remoteValidator: remoteStub)

        await #expect(throws: maliciousError) {
            try await sut.validate([sampleTransaction])
        }

        #expect(localSpy.validateCallCount == 1)
    }

    // MARK: - Single Validator

    @Test
    func onlyLocalValidatorCalled() async throws {
        let localSpy = ComposerValidatorSpy()
        let sut = SUT(localValidator: localSpy, remoteValidator: nil)

        try await sut.validate([sampleTransaction])

        #expect(localSpy.validateCallCount == 1)
    }

    @Test
    func onlyRemoteValidatorCalled() async throws {
        let remoteSpy = ComposerValidatorSpy()
        let sut = SUT(localValidator: nil, remoteValidator: remoteSpy)

        try await sut.validate([sampleTransaction])

        #expect(remoteSpy.validateCallCount == 1)
    }

    // MARK: - No Validators

    @Test
    func noValidatorsDoesNotThrow() async throws {
        let sut = SUT(localValidator: nil, remoteValidator: nil)

        try await sut.validate(sampleTransactions)
    }

    // MARK: - Empty Transactions

    @Test
    func emptyTransactionsPassedToValidators() async throws {
        let localSpy = ComposerValidatorSpy()
        let remoteSpy = ComposerValidatorSpy()
        let sut = SUT(localValidator: localSpy, remoteValidator: remoteSpy)

        try await sut.validate([])

        #expect(localSpy.validateCallCount == 1)
        #expect(remoteSpy.validateCallCount == 1)
        #expect(localSpy.lastTransactions == [])
        #expect(remoteSpy.lastTransactions == [])
    }
}

// MARK: - Test Data

private extension StakingValidationComposerTests {
    var sampleTransaction: String { "sample_tx" }
    var sampleTransactions: [String] { ["tx_1", "tx_2"] }
    var maliciousError: RemoteStakingValidationError { .malicious(description: "Scam") }
}

// MARK: - Test Doubles

private final class ComposerValidatorSpy: StakingTransactionValidator {
    private(set) var validateCallCount = 0
    private(set) var lastTransactions: [String]?

    func validate(_ unsignedTransactions: [String]) async throws {
        validateCallCount += 1
        lastTransactions = unsignedTransactions
    }
}

private struct ComposerValidatorErrorStub: StakingTransactionValidator {
    let error: any Error

    func validate(_ unsignedTransactions: [String]) async throws {
        throw error
    }
}
