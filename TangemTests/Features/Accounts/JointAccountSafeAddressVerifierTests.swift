//
//  JointAccountSafeAddressVerifierTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tests for checking a joint account against the address it was announced at")
struct JointAccountSafeAddressVerifierTests {
    @Test("An address the composition resolves to under either master copy is confirmed", arguments: [
        "0x9295a5836685C5F5f42242f9B64d23E46F8c259F",
        "0x30bE590176A93C6Ef687F3b07421A3624deaf476",
    ])
    func announcedAddressOfTheCompositionIsConfirmed(announcedAddress: String) throws {
        let address = try JointAccountSafeAddressVerifier.confirm(
            announcedAddress: announcedAddress,
            owners: Constants.owners,
            threshold: 2
        )

        #expect(address == announcedAddress)
    }

    /// The backend keeps addresses in lower case while the app computes the checksummed form, so the two are never
    /// compared as strings — and the backend's spelling is what gets signed, since it compares the config it holds
    /// character by character.
    @Test("The letter case the address is announced in does not decide whether it matches, and is kept")
    func announcedAddressIsMatchedRegardlessOfCase() throws {
        let address = try JointAccountSafeAddressVerifier.confirm(
            announcedAddress: "0x9295a5836685c5f5f42242f9b64d23e46f8c259f",
            owners: Constants.owners,
            threshold: 2
        )

        #expect(address == "0x9295a5836685c5f5f42242f9b64d23e46f8c259f")
    }

    @Test("An address the composition does not resolve to is refused")
    func announcedAddressOfAnotherCompositionIsRefused() {
        #expect(throws: JointAccountSafeAddressVerifier.VerificationError.addressMismatch) {
            // The address of the same owners under a threshold of three
            try JointAccountSafeAddressVerifier.confirm(
                announcedAddress: "0x9295a5836685C5F5f42242f9B64d23E46F8c259F",
                owners: Constants.owners,
                threshold: 3
            )
        }
    }

    @Test("A composition that belongs to no deployable Safe is refused before any address is matched")
    func undeployableCompositionIsRefused() {
        let expected = JointAccountSafeAddressVerifier.VerificationError.undeployableComposition(
            .thresholdOutOfRange(threshold: 4, ownersCount: 3)
        )

        #expect(throws: expected) {
            try JointAccountSafeAddressVerifier.confirm(
                announcedAddress: "0x9295a5836685C5F5f42242f9B64d23E46F8c259F",
                owners: Constants.owners,
                threshold: 4
            )
        }
    }
}

// MARK: - Constants

private extension JointAccountSafeAddressVerifierTests {
    enum Constants {
        static let owners = [
            "0xa9936482d7d056d6f843f5C6088Ff0123b796bCC",
            "0xB8C09e7abE7e0F70f4F4cAf48eED46cc8BfdA120",
            "0xD048326c01787c475Af00C51eb0221d2557bfEc2",
        ]
    }
}
