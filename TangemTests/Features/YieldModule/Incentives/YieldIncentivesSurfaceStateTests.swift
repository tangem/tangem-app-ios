//
//  YieldIncentivesSurfaceStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import Tangem

@Suite("YieldIncentivesSurfaceState")
struct YieldIncentivesSurfaceStateTests {
    private typealias Fixtures = YieldIncentivesFixtures

    @Test("An inactive campaign with nothing to claim hides every incentive surface", arguments: [false, true])
    func inactiveCampaignWithoutClaimableRewardsHidesEverything(isClaimInFlight: Bool) {
        let withoutSummary = YieldIncentivesSurfaceState.make(
            campaignActive: false,
            summary: nil,
            isClaimInFlight: isClaimInFlight
        )

        let pendingOnly = YieldIncentivesSurfaceState.make(
            campaignActive: false,
            summary: Fixtures.summary(rewards: [Fixtures.reward(claimableAmount: 0)]),
            isClaimInFlight: isClaimInFlight
        )

        #expect(withoutSummary == .none)
        #expect(pendingOnly == .none)
    }

    @Test("Rewards left claimable after the campaign ends keep the claim")
    func claimableRewardsOutliveTheCampaign() {
        let recommended = YieldIncentivesSurfaceState.make(
            campaignActive: false,
            summary: Fixtures.summary(),
            isClaimInFlight: false
        )

        let belowThreshold = YieldIncentivesSurfaceState.make(
            campaignActive: false,
            summary: Fixtures.summary(isClaimRecommended: false),
            isClaimInFlight: false
        )

        let inFlight = YieldIncentivesSurfaceState.make(
            campaignActive: false,
            summary: Fixtures.summary(),
            isClaimInFlight: true
        )

        #expect(recommended == .claimAvailable)
        #expect(belowThreshold == .belowThreshold)
        #expect(inFlight == .claimInFlight)
    }

    @Test("An active campaign without a summary shows the APY overlay alone", arguments: [false, true])
    func missingSummaryShowsOverlayOnly(isClaimInFlight: Bool) {
        let state = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: nil,
            isClaimInFlight: isClaimInFlight
        )

        #expect(state == .apyOverlayOnly)
    }

    @Test("A recommended claimable reward enables the claim")
    func recommendedRewardEnablesClaim() {
        let state = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: Fixtures.summary(),
            isClaimInFlight: false
        )

        #expect(state == .claimAvailable)
    }

    @Test("A claimable reward below the backend threshold stays visible without the claim")
    func belowThresholdRewardKeepsClaimDisabled() {
        let state = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: Fixtures.summary(isClaimRecommended: false),
            isClaimInFlight: false
        )

        #expect(state == .belowThreshold)
    }

    @Test("A claim in flight outranks the recommendation")
    func claimInFlightOutranksRecommendation() {
        let recommended = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: Fixtures.summary(),
            isClaimInFlight: true
        )

        let belowThreshold = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: Fixtures.summary(isClaimRecommended: false),
            isClaimInFlight: true
        )

        #expect(recommended == .claimInFlight)
        #expect(belowThreshold == .claimInFlight)
    }

    @Test("Rewards that are only pending leave nothing to claim")
    func pendingOnlyRewardsShowOverlayOnly() {
        let state = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: Fixtures.summary(rewards: [Fixtures.reward(claimableAmount: 0)]),
            isClaimInFlight: false
        )

        #expect(state == .apyOverlayOnly)
    }

    @Test("An unsupported destination leaves nothing to claim even with an amount behind it")
    func unsupportedRewardsShowOverlayOnly() {
        let state = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: Fixtures.summary(rewards: [Fixtures.reward(destination: .unsupported)]),
            isClaimInFlight: false
        )

        #expect(state == .apyOverlayOnly)
    }

    @Test("An empty rewards list shows the APY overlay alone")
    func emptyRewardsShowOverlayOnly() {
        let state = YieldIncentivesSurfaceState.make(
            campaignActive: true,
            summary: Fixtures.summary(rewards: []),
            isClaimInFlight: false
        )

        #expect(state == .apyOverlayOnly)
    }
}
