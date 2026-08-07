//
//  LocalStakingTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("LocalStakingTransactionValidator Tests")
struct LocalStakingTransactionValidatorTests {
    typealias SUT = LocalStakingTransactionValidator

    // MARK: - Routing to Blockchain-Specific Validators

    @Test(arguments: LocalStakingSupportedNetwork.allCases)
    func malformedDataFailsForAllNetworks(network: LocalStakingSupportedNetwork) async {
        await expectValidationFails(network: network, transactions: [malformedData])
    }

    // MARK: - Multiple Transactions

    @Test
    func multipleTransactionsAllValidated() async {
        // Only the LAST element is invalid — proves every tx is validated, not just the first.
        await expectValidationFails(transactions: [validTronHex, validTronHex, malformedData])
    }

    @Test
    func batchThrowsErrorOfFirstInvalidTransaction() async {
        let sut = makeSUT()

        await #expect(throws: StakingTransactionValidationError.emptyOrMalformedData) {
            try await sut.validate([emptyData, validTronHex])
        }
    }

    // MARK: - Empty Transactions

    @Test
    func emptyArrayPasses() async throws {
        let sut = makeSUT()

        try await sut.validate([])
    }
}

// MARK: - SUT Factory

private extension LocalStakingTransactionValidatorTests {
    func makeSUT(network: LocalStakingSupportedNetwork = .tron) -> SUT {
        SUT(network: network)
    }

    func expectValidationFails(
        network: LocalStakingSupportedNetwork = .tron,
        transactions: [String]
    ) async {
        let sut = makeSUT(network: network)
        await #expect(throws: StakingTransactionValidationError.self) {
            try await sut.validate(transactions)
        }
    }
}

// MARK: - Test Data

private extension LocalStakingTransactionValidatorTests {
    var malformedData: String { "malformed_data" }
    var emptyData: String { "" }
    /// Real UnfreezeBalanceV2 tx (Notion doc) — accepted by the `.tron` validator.
    var validTronHex: String {
        "0a0233952208c993bda88c4852d54090a687c0d4325a5b083712570a36747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e556e667265657a6542616c616e63655632436f6e7472616374121d0a15416eb6eb0ba10e8dc827356eef03a49e979d8a7db110c0843d180170d0a9f1bfd432"
    }
}
