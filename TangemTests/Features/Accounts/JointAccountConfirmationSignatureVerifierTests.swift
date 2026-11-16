//
//  JointAccountConfirmationSignatureVerifierTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tests for checking every member signed the joint account they belong to")
struct JointAccountConfirmationSignatureVerifierTests {
    @Test("An account every member has signed over its own composition is confirmed, even with its safe address checksummed")
    func fullySignedAccountIsConfirmed() {
        #expect(
            JointAccountConfirmationSignatureVerifier.allMembersConfirmed(
                config: Constants.config,
                safeAddress: Constants.checksummedSafeAddress,
                members: Constants.signedMembers
            )
        )
    }

    @Test("The case a member's address is spelled in does not decide whether its signature matches")
    func signerIsMatchedRegardlessOfCase() {
        let lowercased = Constants.signedMembers.map { Self.member($0.address.lowercased(), signature: $0.signature) }

        #expect(
            JointAccountConfirmationSignatureVerifier.allMembersConfirmed(
                config: Constants.config,
                safeAddress: Constants.safeAddress,
                members: lowercased
            )
        )
    }

    @Test(
        "A member whose signature is missing, another's, the wrong length, or carries a recovery id the Safe never uses leaves the account unconfirmed",
        arguments: [
            nil,
            Constants.member2Signature,
            String(Constants.member1Signature.dropLast(2)),
            String(Constants.member1Signature.dropLast(2)) + "00",
        ]
    )
    func oneUnverifiedMemberBlocksTheAccount(firstMemberSignature: String?) {
        let members = [
            Self.member(Constants.member1Address, signature: firstMemberSignature),
            Self.member(Constants.member2Address, signature: Constants.member2Signature),
            Self.member(Constants.member3Address, signature: Constants.member3Signature),
        ]

        #expect(
            !JointAccountConfirmationSignatureVerifier.allMembersConfirmed(
                config: Constants.config,
                safeAddress: Constants.safeAddress,
                members: members
            )
        )
    }

    @Test("Signatures made over one composition do not confirm another", arguments: [
        JointAccountSignedConfig(name: "Joint account", icon: "Family", iconColor: "Azure", membersCount: 3, threshold: 3),
        JointAccountSignedConfig(name: "Friends", icon: "Family", iconColor: "Azure", membersCount: 3, threshold: 2),
    ])
    func signaturesDoNotCarryToAnotherComposition(config: JointAccountSignedConfig) {
        #expect(
            !JointAccountConfirmationSignatureVerifier.allMembersConfirmed(
                config: config,
                safeAddress: Constants.safeAddress,
                members: Constants.signedMembers
            )
        )
    }

    @Test("An account carrying fewer members than its composition counts is not confirmed, even if those present signed")
    func fewerMembersThanTheCompositionCountsIsNotConfirmed() {
        #expect(
            !JointAccountConfirmationSignatureVerifier.allMembersConfirmed(
                config: Constants.config,
                safeAddress: Constants.safeAddress,
                members: Array(Constants.signedMembers.dropLast())
            )
        )
    }

    @Test("Signatures made for one safe address do not confirm another")
    func signaturesDoNotCarryToAnotherSafeAddress() {
        #expect(
            !JointAccountConfirmationSignatureVerifier.allMembersConfirmed(
                config: Constants.config,
                safeAddress: "0x9295a5836685c5f5f42242f9b64d23e46f8c259f",
                members: Constants.signedMembers
            )
        )
    }
}

// MARK: - Helpers

private extension JointAccountConfirmationSignatureVerifierTests {
    static func member(_ address: String, signature: String?) -> StoredJointAccount.Member {
        StoredJointAccount.Member(name: "Member", address: address, role: .member, slot: nil, signature: signature)
    }
}

// MARK: - Constants

private extension JointAccountConfirmationSignatureVerifierTests {
    typealias Constants = JointAccountCompositionFixture.Signed
}
