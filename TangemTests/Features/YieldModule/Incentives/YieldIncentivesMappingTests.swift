//
//  YieldIncentivesMappingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import Tangem

@Suite("Yield incentives mapping")
struct YieldIncentivesMappingTests {
    @Test("A reward arrives with its amounts, decimals and destination intact")
    func rewardCarriesTheBackendValues() throws {
        let summary = try #require(makeSummary(rewards: [rewardJSON()]))
        let reward = try #require(summary.rewards.first)

        #expect(summary.moduleAddress == "0xd4212f886c1b209d06a463c02df2607cfbf80676")
        #expect(summary.isClaimRecommended)
        #expect(reward.rewardTokenAddress == "0x561ad6156d0106e7a59ee788759df7b7ec679bd0")
        #expect(reward.symbol == "WMON")
        #expect(reward.decimals == 18)
        #expect(reward.claimableAmount == BigUInt(stringLiteral: "61086786758864400"))
        #expect(reward.pendingAmount == BigUInt(stringLiteral: "1361210927042815"))
        #expect(reward.serviceFeeRateBps == 1500)
        #expect(reward.destination == .owner)
        #expect(reward.isClaimable)
    }

    @Test(
        "The destination is read without regard to the case the backend sends",
        arguments: ["owner", "Owner", "OWNER"]
    )
    func destinationIsReadCaseInsensitively(finalDestination: String) throws {
        let summary = try #require(makeSummary(rewards: [rewardJSON(finalDestination: finalDestination)]))
        let reward = try #require(summary.rewards.first)

        #expect(reward.destination == .owner)
        #expect(reward.isClaimable)
    }

    @Test("A destination this app does not know leaves the reward unclaimable")
    func unknownDestinationIsUnsupported() throws {
        let summary = try #require(makeSummary(rewards: [rewardJSON(finalDestination: "treasury")]))
        let reward = try #require(summary.rewards.first)

        #expect(reward.destination == .unsupported)
        #expect(!reward.isClaimable)
        #expect(summary.claimableRewards.isEmpty)
    }

    @Test(
        "A service fee rate outside the whole range is clamped before it reaches the net amount",
        arguments: [(-500, 0), (20_000, 10_000), (1500, 1500)]
    )
    func serviceFeeRateIsClamped(sent: Int, expected: Int) throws {
        let summary = try #require(makeSummary(rewards: [rewardJSON(serviceFeeRateBps: sent)]))
        let reward = try #require(summary.rewards.first)

        #expect(reward.serviceFeeRateBps == expected)
    }

    @Test("A clamped rate keeps the net amount inside the claim")
    func clampedRateKeepsTheNetAmountSane() throws {
        let summary = try #require(
            makeSummary(rewards: [rewardJSON(claimableAmount: "1000", serviceFeeRateBps: 20_000)])
        )
        let reward = try #require(summary.rewards.first)

        #expect(reward.estimatedNetClaimableAmount == 0)
    }

    @Test("A response without a module carries no rewards surface")
    func responseWithoutAModuleIsNotASummary() throws {
        #expect(makeSummary(moduleAddress: nil, rewards: [rewardJSON()]) == nil)
    }

    @Test("A response without rewards carries no rewards surface")
    func responseWithoutRewardsIsNotASummary() throws {
        #expect(makeSummary(rewards: []) == nil)
    }

    @Test("The recommendation comes from the response, not from the rewards")
    func recommendationComesFromTheResponse() throws {
        let summary = try #require(makeSummary(rewards: [rewardJSON()], claimRecommended: false))

        #expect(!summary.isClaimRecommended)
        #expect(!summary.claimableRewards.isEmpty)
    }

    private func makeSummary(
        moduleAddress: String? = "0xd4212f886c1b209d06a463c02df2607cfbf80676",
        rewards: [String],
        claimRecommended: Bool = true
    ) -> YieldIncentivesRewardsSummary? {
        let module = moduleAddress.map { "\"\($0)\"" } ?? "null"
        let json = """
        {
          "chainId": 143,
          "userAddress": "0xd7abce6612079a05e431752cb85bf7010e40fdf5",
          "moduleAddress": \(module),
          "rewards": [\(rewards.joined(separator: ","))],
          "lastUpdatedAt": "2026-09-28T11:00:17.649Z",
          "claimRecommended": \(claimRecommended)
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        guard let dto = try? decoder.decode(YieldModuleDTO.Response.IncentivesInfo.self, from: Data(json.utf8)) else {
            Issue.record("The incentives payload did not decode")
            return nil
        }

        return YieldIncentivesRewardsSummary(dto: dto)
    }

    private func rewardJSON(
        claimableAmount: String = "61086786758864400",
        serviceFeeRateBps: Int = 1500,
        finalDestination: String = "owner"
    ) -> String {
        """
        {
          "source": "merkl",
          "protocol": "aave",
          "rewardToken": "0x561ad6156d0106e7a59ee788759df7b7ec679bd0",
          "symbol": "WMON",
          "tokenDecimals": 18,
          "claimableAmount": "\(claimableAmount)",
          "pendingAmount": "1361210927042815",
          "usdValue": 0.0016724676356365405,
          "serviceFeeRateBps": \(serviceFeeRateBps),
          "estimatedServiceFeeUsd": 0.0002508701453454811,
          "estimatedSponsoredGasUsd": 0.00111305868,
          "estimatedNetValueUsd": 0.0014215974902910594,
          "finalDestination": "\(finalDestination)"
        }
        """
    }
}
