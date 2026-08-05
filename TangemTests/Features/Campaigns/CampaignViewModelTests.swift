//
//  CampaignViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("CampaignViewModel", .tags(.campaigns), .serialized)
final class CampaignViewModelTests: LeakTrackingTestSuite {
    private typealias Fixtures = PromotionCampaignsFixtures

    private let whaleSwapCampaignId = CashbackCampaign.whaleSwap.rawValue

    // MARK: - Loading

    @Test("Active campaign inside the date window shows the summary")
    func activeCampaignShowsSummary() async {
        let spy = makeApiSpy(promotions: [makeActivePromotion()])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT()
            #expect(await waitUntilConditionMet { sut.viewState == .summary })
        }
    }

    @Test("Unknown campaign id shows not-active even when the backend reports an active campaign")
    func unknownCampaignIdShowsNotActive() async {
        let spy = makeApiSpy(promotions: [makeActivePromotion(name: "unknown-campaign")])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT(campaignId: "unknown-campaign")
            #expect(await waitUntilConditionMet { sut.viewState == .campaignNotActive })
        }
    }

    @Test("Missing campaign data shows not-active")
    func missingCampaignShowsNotActive() async {
        let spy = makeApiSpy(promotions: [])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT()
            #expect(await waitUntilConditionMet { sut.viewState == .campaignNotActive })
        }
    }

    @Test("Non-active backend status shows not-active", arguments: [
        BannerPromotion.Response.Status.pending,
        BannerPromotion.Response.Status.finished,
    ])
    func nonActiveStatusShowsNotActive(status: BannerPromotion.Response.Status) async {
        let spy = makeApiSpy(promotions: [makeActivePromotion(status: status)])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT()
            #expect(await waitUntilConditionMet { sut.viewState == .campaignNotActive })
        }
    }

    @Test("Campaign that has not started yet shows not-active")
    func notStartedCampaignShowsNotActive() async {
        let spy = makeApiSpy(promotions: [
            makeActivePromotion(start: Date().addingTimeInterval(.day), end: Date().addingTimeInterval(2 * .day)),
        ])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT()
            #expect(await waitUntilConditionMet { sut.viewState == .campaignNotActive })
        }
    }

    @Test("Campaign that has already ended shows not-active")
    func endedCampaignShowsNotActive() async {
        let spy = makeApiSpy(promotions: [
            makeActivePromotion(start: Date().addingTimeInterval(-2 * .day), end: Date().addingTimeInterval(-.day)),
        ])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT()
            #expect(await waitUntilConditionMet { sut.viewState == .campaignNotActive })
        }
    }

    @Test("Campaign loads only once per view model lifecycle")
    func campaignLoadsOnlyOnce() async {
        let spy = makeApiSpy(promotions: [makeActivePromotion()])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT()

            #expect(await waitUntilConditionMet { sut.viewState == .summary })
            #expect(spy.requestedWalletIds.count == 1)
        }
    }

    @Test("Not-active initial state stays as is and does not query the backend")
    func notActiveInitialStateDoesNotLoad() async {
        let spy = makeApiSpy(promotions: [makeActivePromotion()])
        let repository = makeRepositoryWithSelectedWallet()

        await withInjectedCampaignDependencies(spy.fake, userWalletRepository: repository) {
            let sut = makeSUT(campaignId: "", initialState: .campaignNotActive)
            #expect(sut.viewState == .campaignNotActive)
            #expect(spy.requestedWalletIds.isEmpty)
        }
    }

    // MARK: - Enrollment

    @Test("Enroll without a selected token does not query the backend")
    func enrollWithoutSelectedTokenIsNoOp() async {
        let apiService = FakeTangemApiService()
        let registerCallCount = OSAllocatedUnfairLock(initialState: 0)
        apiService.registerForPromotionCampaignHandler = { _ in
            registerCallCount.withLock { $0 += 1 }
            return PromotionRegistrationDTO.Response(status: .saved)
        }

        await withInjectedCampaignDependencies(apiService) {
            let sut = makeSUT(initialState: .summary)

            sut.enroll()

            #expect(!sut.isEnrolling)
            #expect(registerCallCount.withLock { $0 } == 0)
        }
    }

    @Test("Enroll registers unlocked wallets only and shows the success state")
    func enrollRegistersUnlockedWalletsAndShowsSuccess() async throws {
        let unlockedWallet = CampaignUserWalletModelStub(walletIdSeed: "unlocked-wallet")
        let lockedWallet = CampaignUserWalletModelStub(walletIdSeed: "locked-wallet", isLocked: true)
        let repository = FakeUserWalletRepository(models: [unlockedWallet, lockedWallet])

        let apiService = FakeTangemApiService()
        let recordedRequests = OSAllocatedUnfairLock(initialState: [PromotionRegistrationDTO.Request]())
        apiService.registerForPromotionCampaignHandler = { request in
            recordedRequests.withLock { $0.append(request) }
            return PromotionRegistrationDTO.Response(status: .saved)
        }

        try await withInjectedCampaignDependencies(apiService, userWalletRepository: repository) {
            let sut = makeSUT(initialState: .summary)
            selectEligibleToken(on: sut)
            #expect(sut.viewState == .readyToEnroll)

            sut.enroll()

            #expect(await waitUntilConditionMet { sut.viewState == .enrollSuccess })
            #expect(!sut.isEnrolling)

            let request = try #require(recordedRequests.withLock { $0.first })
            #expect(request.campaignId == whaleSwapCampaignId)
            #expect(request.walletIds == [unlockedWallet.userWalletId.stringValue])
            #expect(request.tokenReward.networkId == "ethereum")
            #expect(request.tokenReward.userAddress == "0xUserAddress")
            #expect(request.tokenReward.tokenAddress == "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
            #expect(request.tokenReward.tokenId == "usd-coin")
        }
    }

    @Test("Already-enrolled backend answer shows the already-activated state")
    func alreadyEnrolledAnswerShowsAlreadyActivated() async {
        let apiService = FakeTangemApiService()
        apiService.registerForPromotionCampaignHandler = { _ in
            PromotionRegistrationDTO.Response(status: .alreadyExists)
        }

        await withInjectedCampaignDependencies(apiService, userWalletRepository: FakeUserWalletRepository(models: [])) {
            let sut = makeSUT(initialState: .summary)
            selectEligibleToken(on: sut)

            sut.enroll()

            #expect(await waitUntilConditionMet { sut.viewState == .alreadyActivated })
            #expect(!sut.isEnrolling)
        }
    }

    @Test("Registration failure resets the enrolling flag, keeps the state, and shows an error toast")
    func registrationFailureShowsErrorToast() async {
        let apiService = FakeTangemApiService()
        apiService.registerForPromotionCampaignHandler = { _ in throw TestError.sample }

        await withInjectedCampaignDependencies(apiService, userWalletRepository: FakeUserWalletRepository(models: [])) {
            let (sut, coordinator) = makeSUTWithCoordinator(initialState: .summary)
            selectEligibleToken(on: sut)

            sut.enroll()

            #expect(await waitUntilConditionMet { coordinator.errorToastTexts.count == 1 })
            #expect(!sut.isEnrolling)
            #expect(sut.viewState == .readyToEnroll)
        }
    }

    @Test("Repeated enroll while a registration is in flight sends a single request")
    func repeatedEnrollSendsSingleRequest() async {
        let apiService = FakeTangemApiService()
        let registerCallCount = OSAllocatedUnfairLock(initialState: 0)
        let gate = AsyncGate()
        apiService.registerForPromotionCampaignHandler = { _ in
            registerCallCount.withLock { $0 += 1 }
            await gate.wait()
            return PromotionRegistrationDTO.Response(status: .saved)
        }

        await withInjectedCampaignDependencies(apiService, userWalletRepository: FakeUserWalletRepository(models: [])) {
            let sut = makeSUT(initialState: .summary)
            selectEligibleToken(on: sut)

            sut.enroll()
            #expect(sut.isEnrolling)
            sut.enroll()
            await gate.open()

            #expect(await waitUntilConditionMet { sut.viewState == .enrollSuccess })
            #expect(registerCallCount.withLock { $0 } == 1)
        }
    }

    // MARK: - Navigation

    @Test("Close forwards to the coordinator")
    func closeForwardsToCoordinator() {
        let (sut, coordinator) = makeSUTWithCoordinator(initialState: .campaignNotActive)

        sut.close()

        #expect(coordinator.closeCampaignCallCount == 1)
    }

    @Test("Learn-more opens the whale-swap blog post")
    func learnMoreOpensBlogPost() {
        let (sut, coordinator) = makeSUTWithCoordinator(initialState: .campaignNotActive)

        sut.openLearnMore()

        #expect(coordinator.openedLearnMoreURLs.map(\.path) == ["/embed/blog/post/whale-swap"])
    }

    @Test("Terms opens the whale-swap terms document")
    func termsOpensTermsDocument() {
        let (sut, coordinator) = makeSUTWithCoordinator(initialState: .campaignNotActive)

        sut.openTerms()

        #expect(coordinator.openedLearnMoreURLs.map(\.absoluteString) == ["https://tangem.com/docs/en/whale-swap-cashback-terms.pdf"])
    }

    @Test("Selecting a token dismisses the selector and moves to ready-to-enroll")
    func selectingTokenMovesToReadyToEnroll() async {
        await withInjectedCampaignDependencies(FakeTangemApiService(), userWalletRepository: FakeUserWalletRepository(models: [])) {
            let sut = makeSUT(initialState: .summary)
            sut.tokenSelectorViewModel = CampaignTokenSelectorViewModel(
                eligibleTokens: [],
                initiallyExpandedAccount: nil,
                onSelect: { _ in },
                onClose: {}
            )

            selectEligibleToken(on: sut)

            #expect(sut.viewState == .readyToEnroll)
            #expect(sut.tokenSelectorViewModel == nil)
            #expect(sut.selectedTokenRowViewModel != nil)
        }
    }
}

// MARK: - Helpers

private extension CampaignViewModelTests {
    func makeSUT(
        campaignId: String? = nil,
        coordinator: CampaignRoutable? = nil,
        initialState: CampaignViewModel.ViewState = .idle
    ) -> CampaignViewModel {
        trackForMemoryLeaks(
            CampaignViewModel(
                campaignId: campaignId ?? whaleSwapCampaignId,
                coordinator: coordinator,
                cashbackPromoService: CashbackPromoService(),
                analyticsLogger: nil,
                initialState: initialState
            )
        )
    }

    func makeSUTWithCoordinator(
        initialState: CampaignViewModel.ViewState = .idle
    ) -> (CampaignViewModel, CampaignRoutableSpy) {
        let coordinator = CampaignRoutableSpy()
        return (makeSUT(coordinator: coordinator, initialState: initialState), coordinator)
    }

    func makeApiSpy(promotions: [BannerPromotion.Response.Promotion]) -> PromotionCampaignsApiSpy {
        PromotionCampaignsApiSpy(promotions: promotions)
    }

    func makeActivePromotion(
        name: String? = nil,
        start: Date = Date().addingTimeInterval(-.day),
        end: Date = Date().addingTimeInterval(.day),
        status: BannerPromotion.Response.Status = .active
    ) -> BannerPromotion.Response.Promotion {
        Fixtures.makePromotion(
            name: name ?? whaleSwapCampaignId,
            start: start,
            end: end,
            status: status
        )
    }

    func makeRepositoryWithSelectedWallet() -> FakeUserWalletRepository {
        let wallet = CampaignUserWalletModelStub(walletIdSeed: "wallet-1")
        let repository = FakeUserWalletRepository(models: [wallet])
        repository.selectedModel = wallet
        return repository
    }

    func selectEligibleToken(on sut: CampaignViewModel) {
        sut.handleSelectedToken(CampaignsFixtures.makeTokenSelectorItem())
    }
}

// MARK: - AsyncGate

/// Holds concurrent callers until the gate opens.
private actor AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen {
            return
        }

        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

private extension TimeInterval {
    static let day: TimeInterval = 86400
}

private enum TestError: Error {
    case sample
}
