//
//  YieldClaimCalldataValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("YieldClaimCalldataValidator")
struct YieldClaimCalldataValidatorTests {
    private typealias Fixtures = YieldIncentivesFixtures
    private typealias Failure = YieldClaimCalldataValidator.Failure

    private let sut = YieldClaimCalldataValidator()

    @Test("Valid calldata decodes into the backend's own destination and payload")
    func validCalldataPasses() throws {
        let validated = try sut.validate(Fixtures.calldata(), context: makeContext())

        #expect(validated.to == Fixtures.moduleAddress)
        #expect(validated.data == Data(hexString: Fixtures.calldataHex))
    }

    @Test("Nothing claimable is refused before anything else is read")
    func nothingClaimableIsRefused() {
        let calldata = Fixtures.calldata(hasClaimable: false, to: nil, data: nil, rewardTokens: [])

        #expect(throws: Failure.nothingClaimable) {
            try sut.validate(calldata, context: makeContext())
        }
    }

    @Test("A claim the backend does not recommend never reaches the card")
    func notRecommendedIsRefused() {
        #expect(throws: Failure.notRecommended) {
            try sut.validate(Fixtures.calldata(claimRecommended: false), context: makeContext())
        }
    }

    @Test(
        "Any missing part of the payload is incomplete calldata",
        arguments: [
            Fixtures.calldata(moduleAddress: nil),
            Fixtures.calldata(to: nil),
            Fixtures.calldata(data: nil),
        ]
    )
    func incompleteCalldataIsRefused(calldata: YieldClaimCalldata) {
        #expect(throws: Failure.incompleteCalldata) {
            try sut.validate(calldata, context: makeContext())
        }
    }

    @Test("Calldata answering for another chain or another owner is refused")
    func contextMismatchIsRefused() {
        #expect(throws: Failure.contextMismatch) {
            try sut.validate(Fixtures.calldata(chainId: 1), context: makeContext())
        }

        #expect(throws: Failure.contextMismatch) {
            try sut.validate(Fixtures.calldata(userAddress: "0x0000000000000000000000000000000000000001"), context: makeContext())
        }
    }

    @Test("The destination must be the module both the calldata and the app know")
    func destinationMismatchIsRefused() {
        let foreignModule = "0x0000000000000000000000000000000000000002"

        #expect(throws: Failure.destinationMismatch) {
            try sut.validate(Fixtures.calldata(to: foreignModule), context: makeContext())
        }

        #expect(throws: Failure.destinationMismatch) {
            try sut.validate(Fixtures.calldata(), context: makeContext(moduleAddress: foreignModule))
        }
    }

    @Test("Calldata whose destination contradicts its own module is refused")
    func calldataContradictingItsOwnModuleIsRefused() {
        let calldata = Fixtures.calldata(moduleAddress: "0x0000000000000000000000000000000000000006")

        #expect(throws: Failure.destinationMismatch) {
            try sut.validate(calldata, context: makeContext())
        }
    }

    @Test("Addresses are compared without regard to case")
    func addressesMatchCaseInsensitively() throws {
        let calldata = Fixtures.calldata(
            userAddress: Fixtures.userAddress.lowercased(),
            moduleAddress: Fixtures.moduleAddress.uppercased(),
            to: Fixtures.moduleAddress.lowercased(),
            rewardTokens: [Fixtures.rewardToken.uppercased()]
        )

        let validated = try sut.validate(calldata, context: makeContext())

        #expect(validated.to == Fixtures.moduleAddress.lowercased())
    }

    @Test(
        "Reward tokens and cumulative amounts must describe the same list",
        arguments: [
            Fixtures.calldata(rewardTokens: [], cumulativeAmounts: []),
            Fixtures.calldata(cumulativeAmounts: ["1", "2"]),
        ]
    )
    func malformedRewardListIsRefused(calldata: YieldClaimCalldata) {
        #expect(throws: Failure.malformedRewardList) {
            try sut.validate(calldata, context: makeContext())
        }
    }

    @Test("One unsupported reward token fails the whole claim rather than being filtered out")
    func unsupportedRewardTokenFailsTheWholeClaim() {
        let unsupported = "0x0000000000000000000000000000000000000003"
        let calldata = Fixtures.calldata(
            rewardTokens: [Fixtures.rewardToken, unsupported],
            cumulativeAmounts: ["1", "2"]
        )

        #expect(throws: Failure.unsupportedRewardToken) {
            try sut.validate(calldata, context: makeContext())
        }
    }

    @Test(
        "A payload that does not survive hex decoding is refused",
        arguments: ["0x", "0xb4701e3e0", "zz", ""]
    )
    func malformedPayloadIsRefused(hex: String) {
        #expect(throws: Failure.malformedCalldata) {
            try sut.validate(Fixtures.calldata(data: hex), context: makeContext())
        }
    }

    @Test("The recommendation is checked before the payload, so a bad payload cannot mask it")
    func recommendationIsCheckedBeforeThePayload() {
        let calldata = Fixtures.calldata(data: "0xb4701e3e0", claimRecommended: false)

        #expect(throws: Failure.notRecommended) {
            try sut.validate(calldata, context: makeContext())
        }
    }

    @Test("The owner is checked before the destination, so a foreign claim cannot mask it")
    func contextIsCheckedBeforeTheDestination() {
        let calldata = Fixtures.calldata(
            userAddress: "0x0000000000000000000000000000000000000001",
            to: "0x0000000000000000000000000000000000000002"
        )

        #expect(throws: Failure.contextMismatch) {
            try sut.validate(calldata, context: makeContext())
        }
    }

    private func makeContext(
        chainId: Int = Fixtures.chainId,
        userAddress: String = Fixtures.userAddress,
        moduleAddress: String = Fixtures.moduleAddress,
        supportedRewardTokens: Set<String> = [Fixtures.rewardToken.lowercased()]
    ) -> YieldClaimCalldataValidator.Context {
        YieldClaimCalldataValidator.Context(
            chainId: chainId,
            userAddress: userAddress,
            moduleAddress: moduleAddress,
            supportedRewardTokens: supportedRewardTokens
        )
    }
}
