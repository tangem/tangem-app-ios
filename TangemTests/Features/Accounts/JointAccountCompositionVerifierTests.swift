//
//  JointAccountCompositionVerifierTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Testing
@testable import Tangem

@Suite("Tests for checking a Safe's composition against the account's members")
struct JointAccountCompositionVerifierTests {
    private let verifier = JointAccountCompositionVerifier()

    @Test("An undeployed Safe is verified by the address its composition resolves to")
    func notDeployedIsVerifiedByAddress() throws {
        try verifier.verify(
            state: .notDeployed,
            safeAddress: try Self.address(of: Constants.members, threshold: 2),
            memberAddresses: Constants.members,
            signersCount: 2
        )
    }

    @Test("An undeployed Safe at an address the composition does not resolve to is refused")
    func notDeployedAtAnotherAddressIsRefused() {
        #expect(throws: JointOperationError.compositionMismatch) {
            try verifier.verify(
                state: .notDeployed,
                safeAddress: Constants.safeAddress,
                memberAddresses: Constants.members,
                signersCount: 2
            )
        }
    }

    @Test("Owners are compared as a set and without regard to case")
    func matchingCompositionPasses() throws {
        let owners = Constants.members.reversed().map { $0.uppercased() }
        let state = SafeContractState.deployed(nonce: 3, owners: owners, threshold: 2)

        try verifier.verify(state: state, safeAddress: Constants.safeAddress, memberAddresses: Constants.members, signersCount: 2)
    }

    @Test("A foreign owner is refused")
    func foreignOwnerIsRefused() {
        let owners = [Constants.members[0], "0x0000000000000000000000000000000000000001"]
        let state = SafeContractState.deployed(nonce: 3, owners: owners, threshold: 2)

        #expect(throws: JointOperationError.compositionMismatch) {
            try verifier.verify(state: state, safeAddress: Constants.safeAddress, memberAddresses: Constants.members, signersCount: 2)
        }
    }

    @Test("Another threshold is refused")
    func otherThresholdIsRefused() {
        let state = SafeContractState.deployed(nonce: 3, owners: Constants.members, threshold: 1)

        #expect(throws: JointOperationError.compositionMismatch) {
            try verifier.verify(state: state, safeAddress: Constants.safeAddress, memberAddresses: Constants.members, signersCount: 2)
        }
    }
}

// MARK: - Helpers

private extension JointAccountCompositionVerifierTests {
    /// What the members and the threshold resolve to under CREATE2, which is where the first operation deploys the Safe.
    static func address(of members: [String], threshold: Int) throws -> String {
        try SafeAddressUtils.compute(owners: members, threshold: threshold, singleton: .safe)
    }
}

// MARK: - Constants

private extension JointAccountCompositionVerifierTests {
    enum Constants {
        static let members = ["0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"]
        /// An address the composition above does not resolve to.
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
    }
}
