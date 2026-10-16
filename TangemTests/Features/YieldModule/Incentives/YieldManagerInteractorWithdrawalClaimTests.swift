//
//  YieldManagerInteractorWithdrawalClaimTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("YieldManagerInteractor withdrawal claim", .serialized, .timeLimit(.minutes(1)))
struct YieldManagerInteractorWithdrawalClaimTests {
    private typealias Fixtures = YieldIncentivesFixtures

    @Test("Rewards left claimable after the campaign ends ride the withdrawal")
    func claimableRewardsOutliveTheCampaign() async throws {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            let prepared = try await sut.prepareWithdrawalClaim()

            #expect(manager.state?.marketInfo?.incentive == nil)
            #expect(prepared?.to == Fixtures.moduleAddress)
            #expect(network.calldataCallCount == 1)
        }
    }

    @Test("Nothing claimable leaves the withdrawal alone without asking for calldata")
    func nothingClaimableSkipsTheClaim() async throws {
        let summaries: [YieldIncentivesRewardsSummary?] = [
            nil,
            Fixtures.summary(rewards: []),
            Fixtures.summary(rewards: [Fixtures.reward(claimableAmount: 0)]),
            Fixtures.summary(rewards: [Fixtures.reward(destination: .unsupported)]),
        ]

        for summary in summaries {
            let network = YieldClaimNetworkManagerStub()
            let manager = YieldClaimManagerStub(incentivesManager: YieldClaimIncentivesManagerStub(summary: summary))

            try await withInjectedYieldNetworkManager(network) {
                let sut = makeSUT(manager: manager)

                let prepared = try await sut.prepareWithdrawalClaim()

                #expect(prepared == nil)
                #expect(network.calldataCallCount == 0)
            }
        }
    }

    @Test("Rewards below the backend threshold stay out of the withdrawal without asking for calldata")
    func belowThresholdRewardsSkipTheClaim() async throws {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub(summary: Fixtures.summary(isClaimRecommended: false))
        let manager = YieldClaimManagerStub(incentivesManager: incentives)

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            let prepared = try await sut.prepareWithdrawalClaim()

            #expect(prepared == nil)
            #expect(network.calldataCallCount == 0)
        }
    }

    @Test("A module without the incentives feature never claims on withdrawal")
    func missingClaimInteractorSkipsTheClaim() async throws {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub()
        let manager = YieldClaimManagerStub(incentivesManager: incentives)

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, hasClaimInteractor: false)

            let prepared = try await sut.prepareWithdrawalClaim()

            #expect(prepared == nil)
            #expect(incentives.incentivesCallCount == 0)
            #expect(network.calldataCallCount == 0)
        }
    }

    @Test("A claim already in flight is not prepared a second time")
    func claimInFlightSkipsTheClaim() async throws {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub()
        let manager = YieldClaimManagerStub(incentivesManager: incentives)
        let tracker = YieldIncentivesClaimTracker()

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)
            _ = await tracker.beginClaim()

            let prepared = try await sut.prepareWithdrawalClaim()

            #expect(prepared == nil)
            #expect(incentives.incentivesCallCount == 0)
            #expect(network.calldataCallCount == 0)
        }
    }

    @Test("A failed rewards load is reported instead of being read as nothing to claim")
    func failedRewardsLoadIsReported() async {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub(error: YieldIncentivesTestError.network)
        let manager = YieldClaimManagerStub(incentivesManager: incentives)

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect(throws: YieldIncentivesTestError.self) {
                _ = try await sut.prepareWithdrawalClaim()
            }

            #expect(network.calldataCallCount == 0)
        }
    }

    private func makeSUT(
        manager: YieldClaimManagerStub,
        tracker: YieldIncentivesClaimTracker = YieldIncentivesClaimTracker(),
        hasClaimInteractor: Bool = true
    ) -> YieldManagerInteractor {
        let claimInteractor = hasClaimInteractor
            ? YieldIncentivesClaimInteractor(
                chainId: Fixtures.chainId,
                userAddress: Fixtures.userAddress,
                manager: manager,
                transactionDispatcher: YieldClaimDispatcherStub(),
                tracker: tracker
            )
            : nil

        return YieldManagerInteractor(
            transactionDispatcher: YieldClaimDispatcherStub(),
            manager: manager,
            claimInteractor: claimInteractor
        )
    }
}
