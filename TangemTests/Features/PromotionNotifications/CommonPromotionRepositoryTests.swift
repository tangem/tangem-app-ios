//
//  CommonPromotionRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import Testing
@testable import Tangem

extension Tag {
    @Tag static var promotions: Self
}

@Suite("CommonPromotionRepository", .tags(.promotions), .serialized)
final class CommonPromotionRepositoryTests {
    private let walletA = UserWalletId(value: Data([0xAA]))
    private let walletB = UserWalletId(value: Data([0xBB]))

    @Test("Refreshing another wallet mid-flight does not drop the first wallet's promotions")
    func refreshingAnotherWalletKeepsBothWallets() async throws {
        let api = GatedPromotionsApi(items: [Self.makeItem(id: 1)])

        try await withInjectedPromotionDependencies(api.fake) {
            let sut = CommonPromotionRepository()

            async let refreshA: Void = sut.loadPromotions(userWalletId: walletA)
            try await api.waitForRequest(walletId: walletA.stringValue)

            async let refreshB: Void = sut.loadPromotions(userWalletId: walletB)
            try await api.waitForRequest(walletId: walletB.stringValue)

            api.open()
            _ = await (refreshA, refreshB)

            let promotionsA = try await Self.waitForPromotions(sut, userWalletId: walletA)
            let promotionsB = try await Self.waitForPromotions(sut, userWalletId: walletB)

            #expect(promotionsA.map(\.id) == [1])
            #expect(promotionsB.map(\.id) == [1])
        }
    }

    @Test("Refreshing the same wallet mid-flight restarts the load and stores the latest result")
    func refreshingSameWalletRestartsTheLoad() async throws {
        let api = GatedPromotionsApi(items: [Self.makeItem(id: 1)])

        try await withInjectedPromotionDependencies(api.fake) {
            let sut = CommonPromotionRepository()

            async let firstRefresh: Void = sut.loadPromotions(userWalletId: walletA)
            try await api.waitForRequest(walletId: walletA.stringValue)

            async let secondRefresh: Void = sut.loadPromotions(userWalletId: walletA)
            try await api.waitForRequests(count: 6, walletId: walletA.stringValue)

            api.open()
            _ = await (firstRefresh, secondRefresh)

            let promotions = try await Self.waitForPromotions(sut, userWalletId: walletA)

            #expect(promotions.map(\.id) == [1])
        }
    }

    @Test("A load whose API never suspends still stores its promotions")
    func immediateApiResponseStoresPromotions() async throws {
        let api = FakeTangemApiService()
        api.loadPromotionsHandler = { _ in PromotionsDTO.Load.Response(items: [Self.makeItem(id: 1)]) }

        try await withInjectedPromotionDependencies(api) {
            let sut = CommonPromotionRepository()

            await sut.loadPromotions(userWalletId: walletA)

            let promotions = try await Self.waitForPromotions(sut, userWalletId: walletA)

            #expect(promotions.map(\.id) == [1])
        }
    }

    @Test("With promo campaigns on, a campaign banner shows only while its campaign is open to the wallet")
    func campaignBannersFollowCampaigns() async throws {
        let api = FakeTangemApiService()
        api.loadPromotionsHandler = { _ in
            PromotionsDTO.Load.Response(items: [
                Self.makeItem(id: 1),
                Self.makeItem(id: 2, campaignId: 15),
                Self.makeItem(id: 3, campaignId: 16),
                Self.makeItem(id: 4, campaignId: 17),
            ])
        }
        let campaigns = PromoCampaignsProviderStub(campaigns: [
            walletA: [
                Self.makeCampaign(id: 15, isEnrolled: false),
                Self.makeCampaign(id: 16, isEnrolled: true),
            ],
        ])

        try await withInjectedPromotionDependencies(api, promoCampaignsRepository: campaigns) {
            let sut = CommonPromotionRepository(isPromoCampaignsEnabled: { true })

            await sut.loadPromotions(userWalletId: walletA)

            let promotions = try await Self.waitForPromotions(sut, userWalletId: walletA)
            #expect(promotions.map(\.id) == [1, 2])

            campaigns.send([Self.makeCampaign(id: 15, isEnrolled: true)], for: walletA)
            #expect(Self.currentPromotions(sut, userWalletId: walletA, placement: .main).map(\.id) == [1])
        }
    }

    @Test("A campaign banner follows the campaigns of its own wallet only")
    func campaignBannersArePerWallet() async throws {
        let api = FakeTangemApiService()
        api.loadPromotionsHandler = { _ in
            PromotionsDTO.Load.Response(items: [Self.makeItem(id: 1), Self.makeItem(id: 2, campaignId: 15)])
        }
        let campaigns = PromoCampaignsProviderStub(campaigns: [walletA: [Self.makeCampaign(id: 15, isEnrolled: false)]])

        try await withInjectedPromotionDependencies(api, promoCampaignsRepository: campaigns) {
            let sut = CommonPromotionRepository(isPromoCampaignsEnabled: { true })

            await sut.loadPromotions(userWalletId: walletA)
            await sut.loadPromotions(userWalletId: walletB)

            let walletAPromotions = try await Self.waitForPromotions(sut, userWalletId: walletA)
            let walletBPromotions = try await Self.waitForPromotions(sut, userWalletId: walletB)

            #expect(walletAPromotions.map(\.id) == [1, 2])
            #expect(walletBPromotions.map(\.id) == [1])
        }
    }

    @Test("A dismissed banner stays hidden when the wallet's campaigns change")
    func dismissedBannerStaysHidden() async throws {
        let api = FakeTangemApiService()
        api.loadPromotionsHandler = { _ in
            PromotionsDTO.Load.Response(items: [Self.makeItem(id: 1), Self.makeItem(id: 2, campaignId: 15)])
        }
        let campaigns = PromoCampaignsProviderStub()
        let received = OSAllocatedUnfairLock<[[Int]]>(initialState: [])

        try await withInjectedPromotionDependencies(api, promoCampaignsRepository: campaigns) {
            let sut = CommonPromotionRepository(isPromoCampaignsEnabled: { true })
            let subscription = sut
                .promotionsPublisher(userWalletId: walletA, placeholder: .main)
                .sink { promotions in received.withLock { $0.append(promotions.map(\.id)) } }

            await sut.loadPromotions(userWalletId: walletA)
            try await Self.waitUntil { received.withLock { $0.last == [1] } }

            await sut.hidePromotion(userWalletId: walletA, displayId: 1)
            try await Self.waitUntil { received.withLock { $0.last == [] } }

            campaigns.send([Self.makeCampaign(id: 15, isEnrolled: false)], for: walletA)

            #expect(received.withLock { $0.last } == [2])
            subscription.cancel()
        }
    }

    @Test("A banner dismissed while a refresh is in flight stays hidden when the refresh lands")
    func dismissalDuringRefresh() async throws {
        let api = GatedPromotionsApi(items: [Self.makeItem(id: 1), Self.makeItem(id: 2)])

        try await withInjectedPromotionDependencies(api.fake) {
            let sut = CommonPromotionRepository()

            async let refresh: Void = sut.loadPromotions(userWalletId: walletA)
            try await api.waitForRequest(walletId: walletA.stringValue)

            await sut.hidePromotion(userWalletId: walletA, displayId: 1)

            api.open()
            await refresh

            let promotions = try await Self.waitForPromotions(sut, userWalletId: walletA)

            #expect(promotions.map(\.id) == [2])
        }
    }

    @Test("With promo campaigns off, campaign banners are hidden and the rest are shown")
    func campaignsOffHidesCampaignBanners() async throws {
        let api = FakeTangemApiService()
        api.loadPromotionsHandler = { _ in
            PromotionsDTO.Load.Response(items: [
                Self.makeItem(id: 1),
                Self.makeItem(id: 2, campaignId: 15),
            ])
        }
        let campaigns = PromoCampaignsProviderStub(campaigns: [walletA: [Self.makeCampaign(id: 15, isEnrolled: false)]])

        try await withInjectedPromotionDependencies(api, promoCampaignsRepository: campaigns) {
            let sut = CommonPromotionRepository(isPromoCampaignsEnabled: { false })

            await sut.loadPromotions(userWalletId: walletA)

            let promotions = try await Self.waitForPromotions(sut, userWalletId: walletA)
            #expect(promotions.map(\.id) == [1])
        }
    }
}

// MARK: - Support

private extension CommonPromotionRepositoryTests {
    static func makeItem(id: Int, placement: PromotionPlacement = .main, campaignId: Int? = nil) -> PromotionsDTO.Load.Item {
        PromotionsDTO.Load.Item(
            id: id,
            placeholder: placement,
            priority: nil,
            title: "Title",
            subtitle: "Subtitle",
            iconUrl: nil,
            deeplink: nil,
            buttonEnabled: nil,
            buttonText: nil,
            dismissable: nil,
            campaignId: campaignId
        )
    }

    static func makeCampaign(id: Int, isEnrolled: Bool) -> PromoCampaign {
        PromoCampaignFixtures.makeCampaign(id: id, isEnrolled: isEnrolled)
    }

    /// Promotions reach subscribers asynchronously, so the cache is polled instead of read once.
    static func waitForPromotions(
        _ sut: CommonPromotionRepository,
        userWalletId: UserWalletId,
        placement: PromotionPlacement = .main
    ) async throws -> [Promotion] {
        for _ in 0 ..< Constants.pollAttempts {
            let promotions = currentPromotions(sut, userWalletId: userWalletId, placement: placement)

            if !promotions.isEmpty {
                return promotions
            }

            try await Task.sleep(nanoseconds: Constants.pollInterval)
        }

        return currentPromotions(sut, userWalletId: userWalletId, placement: placement)
    }

    static func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0 ..< Constants.pollAttempts {
            if condition() {
                return
            }

            try await Task.sleep(nanoseconds: Constants.pollInterval)
        }

        Issue.record("Timed out waiting for the condition")
    }

    static func currentPromotions(
        _ sut: CommonPromotionRepository,
        userWalletId: UserWalletId,
        placement: PromotionPlacement
    ) -> [Promotion] {
        var promotions: [Promotion] = []
        let subscription = sut
            .promotionsPublisher(userWalletId: userWalletId, placeholder: placement)
            .sink { promotions = $0 }
        subscription.cancel()

        return promotions
    }

    enum Constants {
        static let pollAttempts = 200
        static let pollInterval: UInt64 = 5_000_000
    }
}

/// `CommonPromotionRepository` reads the wallet repository through `@Injected`, so both globals are swapped together.
private func withInjectedPromotionDependencies(
    _ apiService: TangemApiService,
    userWalletRepository: UserWalletRepository = FakeUserWalletRepository(models: []),
    promoCampaignsRepository: PromoCampaignsProviding = PromoCampaignsProviderStub(),
    operation: () async throws -> Void
) async rethrows {
    try await InjectedDependenciesIsolation.shared.run {
        let previousApiService = InjectedValues[\.tangemApiService]
        let previousUserWalletRepository = InjectedValues[\.userWalletRepository]
        let previousPromoCampaignsRepository = InjectedValues[\.promoCampaignsRepository]
        InjectedValues[\.tangemApiService] = apiService
        InjectedValues[\.userWalletRepository] = userWalletRepository
        InjectedValues[\.promoCampaignsRepository] = promoCampaignsRepository

        defer {
            InjectedValues[\.tangemApiService] = previousApiService
            InjectedValues[\.userWalletRepository] = previousUserWalletRepository
            InjectedValues[\.promoCampaignsRepository] = previousPromoCampaignsRepository
        }

        try await operation()
    }
}

/// Records every promotions request and suspends all of them until `open()` is called.
private final class GatedPromotionsApi {
    let fake = FakeTangemApiService()

    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var requestedWalletIds: [String] = []
        var isOpen = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    init(items: [PromotionsDTO.Load.Item]) {
        fake.loadPromotionsHandler = { [state] request in
            let isOpen = state.withLock { state -> Bool in
                state.requestedWalletIds.append(request.walletId)
                return state.isOpen
            }

            if !isOpen {
                await withCheckedContinuation { continuation in
                    let resumeImmediately = state.withLock { state -> Bool in
                        guard !state.isOpen else {
                            return true
                        }

                        state.waiters.append(continuation)
                        return false
                    }

                    if resumeImmediately {
                        continuation.resume()
                    }
                }
            }

            return PromotionsDTO.Load.Response(items: items)
        }
    }

    func open() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.isOpen = true
            let waiters = state.waiters
            state.waiters.removeAll()
            return waiters
        }

        waiters.forEach { $0.resume() }
    }

    func waitForRequest(walletId: String) async throws {
        try await waitForRequests(count: 1, walletId: walletId)
    }

    func waitForRequests(count: Int, walletId: String) async throws {
        for _ in 0 ..< CommonPromotionRepositoryTests.Constants.pollAttempts {
            let requestCount = state.withLock { state in
                state.requestedWalletIds.filter { $0 == walletId }.count
            }

            if requestCount >= count {
                return
            }

            try await Task.sleep(nanoseconds: CommonPromotionRepositoryTests.Constants.pollInterval)
        }

        Issue.record("Timed out waiting for \(count) promotions request(s) for \(walletId)")
    }
}

private final class PromoCampaignsProviderStub: PromoCampaignsProviding {
    private let subject: CurrentValueSubject<[UserWalletId: [PromoCampaign]], Never>

    init(campaigns: [UserWalletId: [PromoCampaign]] = [:]) {
        subject = CurrentValueSubject(campaigns)
    }

    func initialize() {}

    func campaignsPublisher(for userWalletId: UserWalletId) -> AnyPublisher<[PromoCampaign], Never> {
        subject
            .map { $0[userWalletId] ?? [] }
            .eraseToAnyPublisher()
    }

    func reloadCampaigns(for userWalletIds: [UserWalletId]) {}

    func removeCampaign(withId campaignId: Int) {}

    func send(_ campaigns: [PromoCampaign], for userWalletId: UserWalletId) {
        subject.value[userWalletId] = campaigns
    }
}
