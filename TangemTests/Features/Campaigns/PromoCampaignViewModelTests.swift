//
//  PromoCampaignViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemTestKit
import Testing
@testable import Tangem

@Suite("PromoCampaignViewModel", .tags(.campaigns), .serialized)
final class PromoCampaignViewModelTests: LeakTrackingTestSuite {
    private let termsURL = URL(string: "https://tangem.com/docs/en/whale-swap-cashback-terms.pdf")!

    @Test("Until a payout token is chosen the button asks for one and the terms stay hidden")
    func awaitingPayoutToken() async {
        await withSelectedWallet {
            let sut = makeSUT(isPayoutNeeded: true)

            #expect(sut.isAwaitingPayoutToken)
            #expect(sut.actionButtonTitle == Localization.promoCampaignSelectToken)
            #expect(sut.termsText == nil)
            #expect(sut.selectedTokenRowViewModel == nil)
        }
    }

    @Test("The action opens the token selector while no payout token is chosen")
    func actionOpensTokenSelector() async {
        await withSelectedWallet {
            let (sut, coordinator) = makeSUTWithCoordinator(isPayoutNeeded: true)

            sut.performAction()

            #expect(sut.tokenSelectorViewModel != nil)
            #expect(coordinator.enrollments.isEmpty)
        }
    }

    @Test("Choosing a payout token closes the selector and shows the token, the terms and the campaign's action")
    func choosingPayoutToken() async {
        await withSelectedWallet {
            let sut = makeSUT(isPayoutNeeded: true)
            sut.selectToken()

            sut.handleSelectedToken(CampaignsFixtures.makeTokenSelectorItem())

            #expect(sut.tokenSelectorViewModel == nil)
            #expect(sut.selectedTokenRowViewModel != nil)
            #expect(!sut.isAwaitingPayoutToken)
            #expect(sut.actionButtonTitle == "Enroll")
            #expect(sut.termsText != nil)
        }
    }

    @Test("With a payout token chosen the action enrolls with that token")
    func enrollWithChosenToken() async {
        await withSelectedWallet {
            let (sut, coordinator) = makeSUTWithCoordinator(isPayoutNeeded: true)
            sut.handleSelectedToken(CampaignsFixtures.makeTokenSelectorItem())

            sut.performAction()

            #expect(coordinator.enrollments.map(\.campaignId) == [42])
            #expect(coordinator.enrollments.first?.tokenItem == CampaignsFixtures.usdcOnEthereum)
        }
    }

    @Test("A campaign without a payout shows the terms and enrolls right away")
    func campaignWithoutPayout() async {
        await withSelectedWallet {
            let (sut, coordinator) = makeSUTWithCoordinator(isPayoutNeeded: false)

            #expect(!sut.isAwaitingPayoutToken)
            #expect(sut.actionButtonTitle == "Enroll")
            #expect(sut.termsText != nil)

            sut.performAction()

            #expect(sut.tokenSelectorViewModel == nil)
            #expect(coordinator.enrollments.map(\.campaignId) == [42])
            #expect(coordinator.enrollments.first?.tokenItem == nil)
        }
    }

    @Test("Enrolling puts the button into the loading state and ignores repeat taps")
    func repeatTapWhileEnrolling() async {
        await withSelectedWallet {
            let (sut, coordinator) = makeSUTWithCoordinator(isPayoutNeeded: false)

            #expect(!sut.isEnrolling)

            sut.performAction()
            sut.performAction()

            #expect(sut.isEnrolling)
            #expect(coordinator.enrollments.map(\.campaignId) == [42])
        }
    }

    @Test("While enrolling, links and the token selector are ignored")
    func linksAndTokenSelectorIgnoredWhileEnrolling() async {
        await withSelectedWallet {
            let (sut, coordinator) = makeSUTWithCoordinator(isPayoutNeeded: false)
            sut.performAction()

            sut.open(termsURL)
            sut.selectToken()

            #expect(coordinator.openedLearnMoreURLs.isEmpty)
            #expect(sut.tokenSelectorViewModel == nil)
        }
    }

    @Test("An enrollment the coordinator doesn't start leaves the button ready for another tap")
    func rejectedEnrollmentIsNotLoading() async {
        await withSelectedWallet {
            let coordinator = PromoCampaignRoutableSpy(startsEnrollment: false)
            let sut = makeSUT(isPayoutNeeded: false, coordinator: coordinator)

            sut.performAction()
            sut.performAction()

            #expect(!sut.isEnrolling)
            #expect(coordinator.enrollments.count == 2)
        }
    }

    @Test("Without a coordinator the button doesn't get stuck loading")
    func noCoordinatorIsNotLoading() async {
        await withSelectedWallet {
            let sut = makeSUT(isPayoutNeeded: false)

            sut.performAction()

            #expect(!sut.isEnrolling)
        }
    }

    @Test("Opening the token selector doesn't put the button into the loading state")
    func tokenSelectionIsNotEnrolling() async {
        await withSelectedWallet {
            let sut = makeSUT(isPayoutNeeded: true)

            sut.performAction()

            #expect(!sut.isEnrolling)
        }
    }

    @Test("A payout campaign without payout tokens disables the action")
    func payoutCampaignWithoutTokens() async {
        await withSelectedWallet {
            let coordinator = PromoCampaignRoutableSpy()
            let sut = trackForMemoryLeaks(PromoCampaignViewModel(
                campaign: makeCampaign(isPayoutNeeded: true, payoutTokens: []),
                coordinator: coordinator
            ))

            sut.performAction()

            #expect(!sut.isActionEnabled)
            #expect(sut.tokenSelectorViewModel == nil)
            #expect(coordinator.enrollments.isEmpty)
        }
    }

    @Test("A payout token that can't be added and isn't held disables the action")
    func unresolvablePayoutToken() async {
        await withSelectedWallet {
            let sut = trackForMemoryLeaks(PromoCampaignViewModel(
                campaign: makeCampaign(isPayoutNeeded: true, payoutTokens: [PromotionCampaignsFixtures.makeEligibleToken(tokenId: nil)]),
                coordinator: nil
            ))

            #expect(!sut.isActionEnabled)
        }
    }

    @Test("A held payout token enables the action even when it can't be added")
    func heldPayoutToken() async {
        await withSelectedWallet(heldTokens: [CampaignsFixtures.usdcOnEthereum]) {
            let sut = trackForMemoryLeaks(PromoCampaignViewModel(
                campaign: makeCampaign(isPayoutNeeded: true, payoutTokens: [PromotionCampaignsFixtures.makeEligibleToken(tokenId: nil)]),
                coordinator: nil
            ))

            #expect(sut.isActionEnabled)
        }
    }

    @Test("A payout token held only on a joint account doesn't enable the action")
    func payoutTokenHeldOnJointAccount() async {
        await withSelectedWallet(jointHeldTokens: [CampaignsFixtures.usdcOnEthereum]) {
            let sut = trackForMemoryLeaks(PromoCampaignViewModel(
                campaign: makeCampaign(isPayoutNeeded: true, payoutTokens: [PromotionCampaignsFixtures.makeEligibleToken(tokenId: nil)]),
                coordinator: nil
            ))

            #expect(!sut.isActionEnabled)
        }
    }

    @Test("The payout token selector leaves joint accounts out")
    func tokenSelectorExcludesJointAccounts() async {
        await withSelectedWallet {
            let sut = makeSUT(isPayoutNeeded: true)

            sut.selectToken()

            #expect(sut.tokenSelectorViewModel?.accountScope == .crypto)
        }
    }

    @Test("A payout token added without a derived wallet doesn't count as held")
    func payoutTokenWithoutDerivation() async {
        await withSelectedWallet(userTokensManager: UserTokensManagerMock(userTokenItems: [CampaignsFixtures.usdcOnEthereum])) {
            let sut = trackForMemoryLeaks(PromoCampaignViewModel(
                campaign: makeCampaign(isPayoutNeeded: true, payoutTokens: [PromotionCampaignsFixtures.makeEligibleToken(tokenId: nil)]),
                coordinator: nil
            ))

            #expect(!sut.isActionEnabled)
        }
    }

    @Test("A payout token already added to the wallet but not derived disables the action")
    func addedPayoutTokenWithoutDerivation() async {
        await withSelectedWallet(userTokensManager: UserTokensManagerMock(containsTokenItem: true)) {
            let sut = makeSUT(isPayoutNeeded: true)

            #expect(!sut.isActionEnabled)
        }
    }

    @Test("An addable payout token enables the action")
    func addablePayoutToken() async {
        await withSelectedWallet {
            let sut = makeSUT(isPayoutNeeded: true)

            #expect(sut.isActionEnabled)
        }
    }

    @Test("Only the terms title links to the terms document")
    func termsLinkCoversTitleOnly() async {
        await withSelectedWallet {
            let sut = makeSUT(isPayoutNeeded: false)

            guard let termsText = sut.termsText else {
                Issue.record("Expected the terms text")
                return
            }

            let linkedRuns = termsText.runs.filter { $0.link != nil }

            #expect(linkedRuns.map { String(termsText[$0.range].characters) } == ["Whale Swap Cashback Terms"])
            #expect(linkedRuns.first?.link == termsURL)
        }
    }

    @Test("Close and links are forwarded to the coordinator")
    func navigationIsForwarded() async {
        await withSelectedWallet {
            let (sut, coordinator) = makeSUTWithCoordinator(isPayoutNeeded: false)

            sut.open(termsURL)
            sut.close()

            #expect(coordinator.openedLearnMoreURLs == [termsURL])
            #expect(coordinator.closeCampaignCallCount == 1)
        }
    }
}

// MARK: - Helpers

private extension PromoCampaignViewModelTests {
    func withSelectedWallet(
        userTokensManager: UserTokensManager = UserTokensManagerMock(),
        heldTokens: [TokenItem] = [],
        jointHeldTokens: [TokenItem] = [],
        operation: () async throws -> Void
    ) async rethrows {
        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = heldTokens.map { WalletModelTestsMock(tokenItem: $0, isEmpty: false) }

        let jointWalletModelsManager = WalletModelsManagerTestsMock()
        jointWalletModelsManager.walletModels = jointHeldTokens.map { WalletModelTestsMock(tokenItem: $0, isEmpty: false) }
        let jointAccounts = jointHeldTokens.isEmpty
            ? []
            : [CampaignJointAccountFixtures.makeJointAccount(walletModelsManager: jointWalletModelsManager)]

        let wallet = CampaignUserWalletModelStub(
            walletIdSeed: "wallet-1",
            config: UserWalletConfigStub(supportedBlockchains: [.ethereum(testnet: false)]),
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager,
            jointAccounts: jointAccounts
        )
        let repository = FakeUserWalletRepository(models: [wallet])
        repository.selectedModel = wallet

        try await withInjectedCampaignDependencies(FakeTangemApiService(), userWalletRepository: repository, operation: operation)
    }

    func makeSUT(isPayoutNeeded: Bool, coordinator: PromoCampaignRoutable? = nil) -> PromoCampaignViewModel {
        trackForMemoryLeaks(PromoCampaignViewModel(campaign: makeCampaign(isPayoutNeeded: isPayoutNeeded), coordinator: coordinator))
    }

    func makeSUTWithCoordinator(isPayoutNeeded: Bool) -> (PromoCampaignViewModel, PromoCampaignRoutableSpy) {
        let coordinator = PromoCampaignRoutableSpy()
        return (makeSUT(isPayoutNeeded: isPayoutNeeded, coordinator: coordinator), coordinator)
    }

    func makeCampaign(isPayoutNeeded: Bool, payoutTokens: [CampaignEligibleToken]? = nil) -> PromoCampaign {
        PromoCampaign(
            id: 42,
            name: "whale_swap_cashback",
            isEnrolled: false,
            content: PromoCampaignContent(
                title: "Enroll in Whale Swap Cashback",
                subtitle: nil,
                imageURL: nil,
                blocks: [.text(title: nil, text: "Earn cashback on every swap from $10K", link: nil)],
                learnMoreLink: nil,
                termsLink: PromoCampaignContent.Link(title: "Whale Swap Cashback Terms", url: termsURL),
                actionButtonTitle: "Enroll"
            ),
            isPayoutNeeded: isPayoutNeeded,
            payoutTokens: payoutTokens ?? (isPayoutNeeded ? [PromotionCampaignsFixtures.makeEligibleToken()] : []),
            matchMode: .strict
        )
    }
}

private final class PromoCampaignRoutableSpy: PromoCampaignRoutable {
    struct Enrollment {
        let campaignId: Int
        let tokenItem: TokenItem?
    }

    private struct State {
        var closeCampaignCallCount = 0
        var openedLearnMoreURLs: [URL] = []
        var enrollments: [Enrollment] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let startsEnrollment: Bool

    init(startsEnrollment: Bool = true) {
        self.startsEnrollment = startsEnrollment
    }

    var closeCampaignCallCount: Int {
        state.withLock { $0.closeCampaignCallCount }
    }

    var openedLearnMoreURLs: [URL] {
        state.withLock { $0.openedLearnMoreURLs }
    }

    var enrollments: [Enrollment] {
        state.withLock { $0.enrollments }
    }

    func closeCampaign() {
        state.withLock { $0.closeCampaignCallCount += 1 }
    }

    func openLearnMore(url: URL) {
        state.withLock { $0.openedLearnMoreURLs.append(url) }
    }

    func presentErrorToast(with text: String) {}

    func enrollInPromoCampaign(_ campaign: PromoCampaign, payoutToken: TokenSelectorItem?) -> Bool {
        state.withLock { $0.enrollments.append(Enrollment(campaignId: campaign.id, tokenItem: payoutToken?.tokenItem)) }
        return startsEnrollment
    }
}
