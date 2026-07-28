//
//  MarketingCampaignsRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("MarketingCampaignsRepository", .tags(.marketingBanners), .serialized)
final class MarketingCampaignsRepositoryTests: LeakTrackingTestSuite {
    private typealias Fixtures = MarketingCampaignsFixtures
    private typealias Snapshot = [String: [MarketingCampaignsDTO.Campaign]]

    private let ethereumCoin: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    private let storage = CachesDirectoryStorage(file: .cachedMarketingCampaigns)

    private func makeSUT(isFeatureAvailable: Bool = true) -> MarketingCampaignsRepository {
        trackForMemoryLeaks(MarketingCampaignsRepository(language: "en", isFeatureAvailable: { isFeatureAvailable }))
    }

    private func makeEthereumCampaign(id: Int = 1) -> MarketingCampaignsDTO.Campaign {
        Fixtures.makeCampaign(id: id, tokens: [Fixtures.makeToken(networkId: "ethereum")])
    }

    private func seedDiskSnapshot(_ snapshot: Snapshot) throws {
        try storage.storeAndWait(value: snapshot)
    }

    private func diskSnapshot() -> Snapshot? {
        try? storage.value()
    }

    @Test("Loaded campaigns are published only for matching tokens")
    func loadPublishesOnlyMatchingBanners() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [
            makeEthereumCampaign(id: 1),
            Fixtures.makeCampaign(id: 2, tokens: [Fixtures.makeToken(networkId: "solana")]),
        ])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let recorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .tokenDetails))

            sut.loadCampaigns(for: .tokenDetails)

            let emitted = await waitUntilConditionMet { recorder.values.last?.standalone.map(\.id) == [1] }
            #expect(emitted)
        }
    }

    @Test("Markets publisher filters campaigns by coingecko id")
    func marketsPublisherFiltersByCoingeckoId() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [
            Fixtures.makeCampaign(id: 1, tokens: [Fixtures.makeToken(id: "bitcoin")]),
            Fixtures.makeCampaign(id: 2, tokens: [Fixtures.makeToken(id: "ethereum")]),
        ])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let recorder = PublisherRecorder(sut.bannersPublisher(forMarketsTokenId: "bitcoin"))

            sut.loadCampaigns(for: .marketsToken)

            let emitted = await waitUntilConditionMet { recorder.values.last?.standalone.map(\.id) == [1] }
            #expect(emitted)
        }
    }

    @Test("Loading one kind leaves other kinds empty")
    func kindsAreIsolated() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [makeEthereumCampaign()])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let tokenDetailsRecorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .tokenDetails))
            let yieldRecorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .yield))

            sut.loadCampaigns(for: .tokenDetails)

            let emitted = await waitUntilConditionMet { tokenDetailsRecorder.values.last?.standalone.isEmpty == false }
            #expect(emitted)
            #expect(yieldRecorder.values.allSatisfy { $0.standalone.isEmpty && $0.linked.isEmpty })
        }
    }

    @Test(
        "Each kind routes to its DTO request",
        arguments: [
            (MarketingCampaignsRepository.Kind.staking, MarketingCampaignsDTO.Request.staking(language: "en")),
            (MarketingCampaignsRepository.Kind.yield, MarketingCampaignsDTO.Request.yield(language: "en")),
            (MarketingCampaignsRepository.Kind.tokenDetails, MarketingCampaignsDTO.Request.tokenDetails(language: "en")),
            (MarketingCampaignsRepository.Kind.marketsToken, MarketingCampaignsDTO.Request.marketsToken(language: "en")),
        ]
    )
    func kindRoutesToRequest(kind: MarketingCampaignsRepository.Kind, expected: MarketingCampaignsDTO.Request) async throws {
        try seedDiskSnapshot([:])
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()

            sut.loadCampaigns(for: kind)

            let requested = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(requested)
            #expect(apiSpy.recordedRequests == [expected])

            // Wait out the rest of the fire-and-forget load (apply + persist): a straggler disk write
            // would corrupt the snapshot seeded by the next test, and the still-running task would trip
            // the leak check on the tracked repository.
            let persisted = await waitUntilConditionMet { [self] in
                diskSnapshot()?.keys.contains(kind.rawValue) == true
            }
            #expect(persisted)
        }
    }

    @Test("Repeated loads of the same kind fetch once")
    func repeatedLoadsFetchOnce() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [makeEthereumCampaign()])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let recorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .tokenDetails))

            sut.loadCampaigns(for: .tokenDetails)
            sut.loadCampaigns(for: .tokenDetails)

            let emitted = await waitUntilConditionMet { recorder.values.last?.standalone.isEmpty == false }
            #expect(emitted)

            sut.loadCampaigns(for: .tokenDetails)
            let refetched = await waitUntilConditionMet(timeout: 0.3) { apiSpy.callCount > 1 }
            #expect(!refetched)
        }
    }

    @Test("Disabled feature never hits the API")
    func disabledFeatureDoesNotLoad() async throws {
        let apiSpy = MarketingCampaignsApiSpy(campaigns: [makeEthereumCampaign()])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(isFeatureAvailable: false)

            sut.loadCampaigns(for: .tokenDetails)

            let called = await waitUntilConditionMet(timeout: 0.3) { apiSpy.callCount > 0 }
            #expect(!called)
        }
    }

    // MARK: - Disk cache

    @Test("Failed load falls back to the disk snapshot of the same kind")
    func failedLoadFallsBackToDiskCache() async throws {
        try seedDiskSnapshot(["tokenDetails": [makeEthereumCampaign(id: 99)]])

        let apiService = FakeTangemApiService()
        apiService.loadMarketingCampaignsHandler = { _ in throw TestError.sample }

        await withInjectedTangemApiService(apiService) {
            let sut = makeSUT()
            let recorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .tokenDetails))

            sut.loadCampaigns(for: .tokenDetails)

            let emitted = await waitUntilConditionMet { recorder.values.last?.standalone.map(\.id) == [99] }
            #expect(emitted)
        }
    }

    @Test("Disk fallback is scoped to the requested kind")
    func diskFallbackIsKindScoped() async throws {
        try seedDiskSnapshot(["tokenDetails": [makeEthereumCampaign(id: 99)]])

        let apiSpy = MarketingCampaignsApiSpy(campaigns: [], error: TestError.sample)

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let recorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .yield))

            sut.loadCampaigns(for: .yield)

            let leaked = await waitUntilConditionMet(timeout: 0.3) {
                recorder.values.contains { !$0.standalone.isEmpty || !$0.linked.isEmpty }
            }
            #expect(!leaked)
        }
    }

    @Test("Failed load is retried on the next request and recovers")
    func failedLoadRetriesAndRecovers() async throws {
        try seedDiskSnapshot([:])

        let attempts = OSAllocatedUnfairLock(initialState: 0)
        let apiService = FakeTangemApiService()
        apiService.loadMarketingCampaignsHandler = { [campaign = makeEthereumCampaign(id: 5)] _ in
            let attempt = attempts.withLock { count -> Int in
                count += 1
                return count
            }

            if attempt == 1 {
                throw TestError.sample
            }

            return MarketingCampaignsDTO.Response(campaigns: [campaign])
        }

        await withInjectedTangemApiService(apiService) {
            let sut = makeSUT()
            let recorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .tokenDetails))

            let recovered = await waitUntilConditionMet {
                sut.loadCampaigns(for: .tokenDetails)
                return recorder.values.last?.standalone.map(\.id) == [5]
            }

            #expect(recovered)
            #expect(attempts.withLock { $0 } == 2)
        }
    }

    @Test("Corrupt disk cache is ignored without crashing")
    func corruptDiskCacheIsIgnored() async throws {
        try storage.storeAndWait(value: "garbage")

        let apiSpy = MarketingCampaignsApiSpy(campaigns: [], error: TestError.sample)

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            let recorder = PublisherRecorder(sut.bannersPublisher(for: ethereumCoin, kind: .tokenDetails))

            sut.loadCampaigns(for: .tokenDetails)

            let requested = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(requested)

            let emittedFromCorruptCache = await waitUntilConditionMet(timeout: 0.3) {
                recorder.values.contains { !$0.standalone.isEmpty || !$0.linked.isEmpty }
            }
            #expect(!emittedFromCorruptCache)
        }
    }

    @Test("Successful load persists the snapshot to disk")
    func successfulLoadPersistsSnapshot() async throws {
        try seedDiskSnapshot([:])

        let apiSpy = MarketingCampaignsApiSpy(campaigns: [makeEthereumCampaign(id: 7)])

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()

            sut.loadCampaigns(for: .tokenDetails)

            let persisted = await waitUntilConditionMet { [self] in
                diskSnapshot()?["tokenDetails"]?.map(\.id) == [7]
            }
            #expect(persisted)
        }
    }
}

private enum TestError: Error {
    case sample
}
