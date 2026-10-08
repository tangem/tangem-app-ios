//
//  PromoCampaignEnrollmentResultViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemTestKit
import Testing
@testable import Tangem

@Suite("PromoCampaignEnrollmentResultViewModel", .tags(.campaigns))
final class PromoCampaignEnrollmentResultViewModelTests: LeakTrackingTestSuite {
    private let campaignName = "Whale Swap Cashback"

    @Test("Enrolling one wallet celebrates without a description or wallets")
    func enrolledOneWallet() {
        let sut = makeSUT(state: .enrolled(campaignName: campaignName, walletCount: 1))

        #expect(sut.appearance == .success)
        #expect(sut.title == Localization.promoCampaignEnrollSuccessTitle(campaignName))
        #expect(sut.description == nil)
        #expect(sut.payoutWallet == nil)
        #expect(sut.enrolledWallets.isEmpty)
        #expect(sut.actionTitle == Localization.commonGotIt)
    }

    @Test("Enrolling several wallets says all of them are enrolled")
    func enrolledSeveralWallets() {
        let sut = makeSUT(state: .enrolled(campaignName: campaignName, walletCount: 2))

        #expect(sut.description == Localization.promoCampaignAllWalletsEnrolled)
        #expect(sut.payoutWallet == nil)
        #expect(sut.enrolledWallets.isEmpty)
    }

    @Test("Already enrolled with one wallet shows its payout and no description")
    func alreadyEnrolledWithPayout() {
        let sut = makeSUT(state: .alreadyEnrolled(campaignName: campaignName, wallets: [
            PromoCampaignEnrollmentFixtures.wallet(name: "Main wallet", hasPayout: true),
        ]))

        #expect(sut.appearance == .info)
        #expect(sut.title == Localization.promoCampaignAlreadyActivatedTitle(campaignName))
        #expect(sut.description == nil)
        #expect(sut.payoutWallet?.name == "Main wallet")
        #expect(sut.enrolledWallets.isEmpty)
        #expect(sut.actionTitle == Localization.commonClose)
    }

    @Test("Already enrolled with one wallet and no payout shows no payout")
    func alreadyEnrolledWithoutPayout() {
        let sut = makeSUT(state: .alreadyEnrolled(campaignName: campaignName, wallets: [
            PromoCampaignEnrollmentFixtures.wallet(name: "Main wallet", hasPayout: false),
        ]))

        #expect(sut.payoutWallet == nil)
    }

    @Test("Already enrolled with several wallets shows no payout")
    func alreadyEnrolledSeveralWallets() {
        let sut = makeSUT(state: .alreadyEnrolled(campaignName: campaignName, wallets: [
            PromoCampaignEnrollmentFixtures.wallet(name: "Main wallet", hasPayout: true),
            PromoCampaignEnrollmentFixtures.wallet(name: "Multi Card", hasPayout: true),
        ]))

        #expect(sut.description == nil)
        #expect(sut.payoutWallet == nil)
    }

    @Test("A partial enrollment lists the enrolled wallets")
    func partiallyEnrolled() {
        let sut = makeSUT(state: .partiallyEnrolled(campaignName: campaignName, enrolledWallets: [
            PromoCampaignEnrollmentFixtures.wallet(name: "Main wallet", hasPayout: false),
            PromoCampaignEnrollmentFixtures.wallet(name: "Multi Card", hasPayout: false),
        ]))

        #expect(sut.appearance == .success)
        #expect(sut.title == Localization.promoCampaignEnrollSuccessTitle(campaignName))
        #expect(sut.description == Localization.promoCampaignSomeWalletsEnrolled)
        #expect(sut.enrolledWallets.map(\.name) == ["Main wallet", "Multi Card"])
        #expect(sut.payoutWallet == nil)
        #expect(sut.actionTitle == Localization.commonGotIt)
    }

    @Test("An unavailable campaign says it no longer exists and only offers to close")
    func campaignUnavailable() {
        let sut = makeSUT(state: .campaignUnavailable)

        #expect(sut.appearance == .warning)
        #expect(sut.title == Localization.promoCampaignUnavailableTitle)
        #expect(sut.description == Localization.promoCampaignNotActiveSubtitle)
        #expect(sut.actionTitle == Localization.commonClose)
    }

    @Test("A campaign that hasn't started asks to come back later and only offers to close")
    func temporarilyUnavailable() {
        let sut = makeSUT(state: .temporarilyUnavailable)

        #expect(sut.appearance == .warning)
        #expect(sut.title == Localization.promoCampaignNotStartedTitle)
        #expect(sut.description == Localization.commonTryAgainLater)
        #expect(sut.actionTitle == Localization.commonClose)
    }

    @Test("A failure says something went wrong and only offers to close")
    func failed() {
        let sut = makeSUT(state: .failed)

        #expect(sut.appearance == .error)
        #expect(sut.title == Localization.commonSomethingWentWrong)
        #expect(sut.description == Localization.commonUnknownError)
        #expect(sut.actionTitle == Localization.commonClose)
    }

    @Test("The action closes the result")
    func actionCloses() {
        let coordinator = PromoCampaignEnrollmentResultRoutableSpy()
        let sut = makeSUT(state: .enrolled(campaignName: campaignName, walletCount: 1), coordinator: coordinator)

        sut.performAction()

        #expect(coordinator.closeCallCount == 1)
    }
}

// MARK: - Helpers

private extension PromoCampaignEnrollmentResultViewModelTests {
    func makeSUT(
        state: PromoCampaignEnrollmentResultViewModel.State,
        coordinator: PromoCampaignEnrollmentResultRoutable? = nil
    ) -> PromoCampaignEnrollmentResultViewModel {
        trackForMemoryLeaks(PromoCampaignEnrollmentResultViewModel(state: state, coordinator: coordinator))
    }
}

private final class PromoCampaignEnrollmentResultRoutableSpy: PromoCampaignEnrollmentResultRoutable {
    private let state = OSAllocatedUnfairLock(initialState: 0)

    var closeCallCount: Int {
        state.withLock { $0 }
    }

    func closePromoCampaignEnrollmentResult() {
        state.withLock { $0 += 1 }
    }
}
