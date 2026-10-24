//
//  StakeKitMapperTargetInfoTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking

@Suite("StakeKit target info mapping")
struct StakeKitMapperTargetInfoTests {
    typealias SUT = StakeKitMapper

    @Test("A preferred validator keeps partial unstake available")
    func preferredValidatorAllowsPartialUnstake() throws {
        let target = try mapTarget(#"{"address": "0xvalidator", "status": "active", "preferred": true}"#)

        #expect(target.preferred)
        #expect(target.allowsPartialUnstake)
    }

    @Test(
        "A validator that is not preferred exits in full only",
        arguments: [
            #"{"address": "0xvalidator", "status": "active", "preferred": false}"#,
            #"{"address": "0xvalidator", "status": "active", "preferred": null}"#,
            #"{"address": "0xvalidator", "status": "active"}"#,
        ]
    )
    func nonPreferredValidatorDisallowsPartialUnstake(json: String) throws {
        let target = try mapTarget(json)

        #expect(!target.preferred)
        #expect(!target.allowsPartialUnstake)
    }
}

// MARK: - Private helpers

private extension StakeKitMapperTargetInfoTests {
    func mapTarget(_ json: String) throws -> StakingTargetInfo {
        let validator = try JSONDecoder().decode(StakeKitDTO.Validator.self, from: Data(json.utf8))
        return SUT().mapToStakingTargetInfo(from: validator, rewardType: .apr)
    }
}
