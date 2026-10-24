//
//  PromoCampaignPrecheckViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemTestKit
import Testing
@testable import Tangem

@Suite("PromoCampaignPrecheckViewModel", .tags(.campaigns))
final class PromoCampaignPrecheckViewModelTests: LeakTrackingTestSuite {
    @Test("Already enrolled with one wallet names the campaign and shows that wallet's payout")
    func alreadyEnrolledOneWallet() {
        let wallet = PromoCampaignEnrollmentFixtures.wallet(name: "Main wallet", hasPayout: true)
        let sut = makeSUT(state: .alreadyEnrolled(campaignName: "Whale Swap Cashback", wallets: [wallet]))

        #expect(sut.title == Localization.promoCampaignAlreadyActivatedTitle("Whale Swap Cashback"))
        #expect(sut.subtitle == nil)
        #expect(sut.payoutWallet?.name == "Main wallet")
    }

    @Test("Already enrolled with several wallets shows no payout")
    func alreadyEnrolledSeveralWallets() {
        let sut = makeSUT(state: .alreadyEnrolled(campaignName: "Whale Swap Cashback", wallets: [
            PromoCampaignEnrollmentFixtures.wallet(name: "Main wallet", hasPayout: true),
            PromoCampaignEnrollmentFixtures.wallet(name: "Multi Card", hasPayout: true),
        ]))

        #expect(sut.title == Localization.promoCampaignAlreadyActivatedTitle("Whale Swap Cashback"))
        #expect(sut.payoutWallet == nil)
    }

    @Test("Already enrolled with one wallet and no payout shows no payout")
    func alreadyEnrolledWithoutPayout() {
        let sut = makeSUT(state: .alreadyEnrolled(
            campaignName: "Whale Swap Cashback",
            wallets: [PromoCampaignEnrollmentFixtures.wallet(name: "Main wallet", hasPayout: false)]
        ))

        #expect(sut.payoutWallet == nil)
    }

    @Test("An unavailable campaign says it no longer exists")
    func campaignUnavailable() {
        let sut = makeSUT(state: .campaignUnavailable)

        #expect(sut.title == Localization.promoCampaignUnavailableTitle)
        #expect(sut.subtitle == Localization.promoCampaignNotActiveSubtitle)
        #expect(sut.payoutWallet == nil)
    }

    @Test("A campaign that hasn't started asks to come back later")
    func temporarilyUnavailable() {
        let sut = makeSUT(state: .temporarilyUnavailable)

        #expect(sut.title == Localization.promoCampaignNotStartedTitle)
        #expect(sut.subtitle == Localization.commonTryAgainLater)
        #expect(sut.payoutWallet == nil)
    }

    @Test("Closing closes the campaign")
    func close() {
        let coordinator = CampaignRoutableSpy()
        let sut = makeSUT(state: .campaignUnavailable, coordinator: coordinator)

        sut.close()

        #expect(coordinator.closeCampaignCallCount == 1)
    }
}

// MARK: - Helpers

private extension PromoCampaignPrecheckViewModelTests {
    func makeSUT(
        state: PromoCampaignPrecheckViewModel.State,
        coordinator: CampaignRoutable? = nil
    ) -> PromoCampaignPrecheckViewModel {
        trackForMemoryLeaks(PromoCampaignPrecheckViewModel(state: state, coordinator: coordinator))
    }
}
