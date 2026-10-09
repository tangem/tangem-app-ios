//
//  PromoCampaignEnrollmentStateMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI
import Testing
@testable import Tangem

@Suite("PromoCampaignEnrollmentStateMapper", .tags(.campaigns))
struct PromoCampaignEnrollmentStateMapperTests {
    private let mainWallet: PromoCampaignWalletModelStub
    private let lockedWallet: PromoCampaignWalletModelStub
    private let campaign = PromoCampaignFixtures.makeCampaign(id: 7)

    init() {
        mainWallet = PromoCampaignWalletModelStub(walletIdSeed: "main", name: "Main wallet")
        lockedWallet = PromoCampaignWalletModelStub(walletIdSeed: "locked", name: "Locked wallet", isLocked: true)
    }

    // MARK: - Pre-check

    @Test("A campaign the wallet hasn't joined opens its sheet")
    func notEnrolledCampaignOpensSheet() {
        let entry = makeSUT().mapToEntry(campaignId: 7, campaigns: [campaign])

        guard case .campaign(let shownCampaign) = entry else {
            Issue.record("Expected the campaign sheet, got \(entry)")
            return
        }

        #expect(shownCampaign == campaign)
    }

    @Test("An enrolled campaign goes to the already-enrolled pre-check without wallets, as no payout is known yet")
    func enrolledCampaignShowsPrecheck() {
        let enrolledCampaign = PromoCampaignFixtures.makeCampaign(id: 7, isEnrolled: true)

        let entry = makeSUT().mapToEntry(
            campaignId: 7,
            campaigns: [PromoCampaignFixtures.makeCampaign(id: 3), enrolledCampaign]
        )

        guard case .precheck(.alreadyEnrolled(let campaignName, let wallets)) = entry else {
            Issue.record("Expected the already-enrolled pre-check, got \(entry)")
            return
        }

        #expect(campaignName == enrolledCampaign.content.title)
        #expect(wallets.isEmpty)
    }

    @Test("A campaign missing from the wallet's cache is unavailable")
    func missingCampaignIsUnavailable() {
        let entry = makeSUT().mapToEntry(
            campaignId: 7,
            campaigns: [PromoCampaignFixtures.makeCampaign(id: 3)]
        )

        guard case .precheck(.campaignUnavailable) = entry else {
            Issue.record("Expected the unavailable pre-check, got \(entry)")
            return
        }
    }

    // MARK: - Result

    @Test("Enrolled reports the campaign name and how many wallets joined")
    func enrolled() {
        let state = makeSUT().mapToResultState(
            .enrolled([enrollment(of: mainWallet), enrollment(of: lockedWallet)]),
            campaign: campaign
        )

        guard case .enrolled(let campaignName, let walletCount) = state else {
            Issue.record("Expected enrolled, got \(state)")
            return
        }

        #expect(campaignName == campaign.content.title)
        #expect(walletCount == 2)
    }

    @Test("Already enrolled lists the wallets with their payout address, subtitle and image")
    func alreadyEnrolled() {
        let state = makeSUT().mapToResultState(
            .alreadyEnrolled([enrollment(of: mainWallet, payoutAddress: "0xPayout")]),
            campaign: campaign
        )

        guard case .alreadyEnrolled(let campaignName, let wallets) = state, let wallet = wallets.first else {
            Issue.record("Expected already enrolled with a wallet, got \(state)")
            return
        }

        #expect(campaignName == campaign.content.title)
        #expect(wallets.count == 1)
        #expect(wallet.name == "Main wallet")
        #expect(wallet.subtitle == "Test")
        #expect(wallet.imageProvider is CardImageProviderMock)
        #expect(wallet.payout?.address == "0xPayout")
    }

    @Test("Partially enrolled lists only the wallets enrolled now")
    @MainActor
    func partiallyEnrolled() async {
        let state = makeSUT().mapToResultState(
            .partiallyEnrolled(enrolled: [enrollment(of: lockedWallet)], alreadyEnrolled: [enrollment(of: mainWallet)]),
            campaign: campaign
        )

        guard case .partiallyEnrolled(let campaignName, let enrolledWallets) = state else {
            Issue.record("Expected partially enrolled, got \(state)")
            return
        }

        guard let enrolledWallet = enrolledWallets.first else {
            Issue.record("Expected an enrolled wallet")
            return
        }

        #expect(campaignName == campaign.content.title)
        #expect(enrolledWallets.map(\.name) == ["Locked wallet"])
        #expect(enrolledWallet.subtitle == "Test")
        let isLocked = await waitUntilConditionMet { enrolledWallet.balanceState == .loaded(text: Localization.commonLocked) }
        #expect(isLocked)
    }

    @Test("Wallets no longer in the app are left out")
    func unknownWalletsAreDropped() {
        let removedWallet = PromoCampaignWalletModelStub(walletIdSeed: "removed", name: "Removed wallet")

        let state = makeSUT().mapToResultState(
            .alreadyEnrolled([enrollment(of: removedWallet), enrollment(of: mainWallet)]),
            campaign: campaign
        )

        guard case .alreadyEnrolled(_, let wallets) = state else {
            Issue.record("Expected already enrolled, got \(state)")
            return
        }

        #expect(wallets.map(\.name) == ["Main wallet"])
    }

    @Test("Unavailable, not started and failed outcomes map to their result screens")
    func unsuccessfulOutcomes() {
        let sut = makeSUT()

        #expect(sut.mapToResultState(.unavailable, campaign: campaign).caseName == "campaignUnavailable")
        #expect(sut.mapToResultState(.temporarilyUnavailable, campaign: campaign).caseName == "temporarilyUnavailable")
        #expect(sut.mapToResultState(.failed, campaign: campaign).caseName == "failed")
    }
}

// MARK: - Helpers

private extension PromoCampaignEnrollmentStateMapperTests {
    func makeSUT() -> PromoCampaignEnrollmentStateMapper {
        PromoCampaignEnrollmentStateMapper(userWalletModels: [mainWallet, lockedWallet])
    }

    func enrollment(of wallet: UserWalletModel, payoutAddress: String? = nil) -> PromoCampaignEnrollment {
        PromoCampaignEnrollment(
            userWalletId: wallet.userWalletId,
            payout: payoutAddress.map {
                PromoCampaignPayout(userAddress: $0, tokenAddress: "0xToken", networkId: "ethereum", token: nil)
            }
        )
    }
}

private extension PromoCampaignEnrollmentResultViewModel.State {
    var caseName: String {
        switch self {
        case .enrolled: "enrolled"
        case .alreadyEnrolled: "alreadyEnrolled"
        case .partiallyEnrolled: "partiallyEnrolled"
        case .campaignUnavailable: "campaignUnavailable"
        case .temporarilyUnavailable: "temporarilyUnavailable"
        case .failed: "failed"
        }
    }
}

private final class PromoCampaignWalletModelStub: UserWalletModelMock {
    private let id: UserWalletId
    private let walletName: String
    private let isLocked: Bool

    init(walletIdSeed: String, name: String, isLocked: Bool = false) {
        id = UserWalletId(value: Data(walletIdSeed.utf8))
        walletName = name
        self.isLocked = isLocked
    }

    override var userWalletId: UserWalletId { id }
    override var name: String { walletName }
    override var isUserWalletLocked: Bool { isLocked }
    override var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { .just(output: .loading(cached: nil)) }
    override var config: UserWalletConfig { UserWalletConfigStub() }
}
