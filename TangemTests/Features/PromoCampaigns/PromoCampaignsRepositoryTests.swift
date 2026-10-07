//
//  PromoCampaignsRepositoryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
import enum Moya.MoyaError
import class Moya.Response
import enum Alamofire.AFError
@testable import Tangem

@Suite("PromoCampaignsRepository")
struct PromoCampaignsRepositoryTests {
    private let walletA = UserWalletId(value: Data([0xAA]))
    private let walletB = UserWalletId(value: Data([0xBB]))

    @Test("Every wallet known at launch is asked about")
    func walletsKnownAtLaunchAreLoaded() async throws {
        let loader = CampaignsLoaderStub()
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA), cardWallet(walletB)]), loader: loader)

        sut.initialize()

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
        #expect(try await waitForCampaigns(sut, userWalletId: walletB) == [CampaignsLoaderStub.campaign])
        #expect(loader.requestedWallets.count == 2)
    }

    @Test("A wallet added after launch is asked about too")
    func walletAddedAfterLaunchIsLoaded() async throws {
        let loader = CampaignsLoaderStub()
        let wallets = WalletsProviderStub()
        let sut = makeSUT(wallets: wallets, loader: loader)

        sut.initialize()
        wallets.set([mobileWallet(walletA)])

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
    }

    @Test("A loaded wallet is not asked about again when the list changes")
    func loadedWalletIsAskedAboutOnce() async throws {
        let loader = CampaignsLoaderStub()
        let wallets = WalletsProviderStub([mobileWallet(walletA)])
        let sut = makeSUT(wallets: wallets, loader: loader)

        sut.initialize()
        try await waitForCampaigns(sut, userWalletId: walletA)

        wallets.set([mobileWallet(walletA), mobileWallet(walletB)])
        try await waitForCampaigns(sut, userWalletId: walletB)

        #expect(loader.requestedWallets.map(\.userWalletId) == [walletA, walletB])
    }

    @Test("A removed wallet drops its campaigns and is asked about again once it is back")
    func removedWalletIsForgotten() async throws {
        let loader = CampaignsLoaderStub()
        let wallets = WalletsProviderStub([mobileWallet(walletA)])
        let sut = makeSUT(wallets: wallets, loader: loader)

        sut.initialize()
        try await waitForCampaigns(sut, userWalletId: walletA)

        wallets.set([])
        try await waitUntil { currentCampaigns(sut, userWalletId: walletA).isEmpty }

        wallets.set([mobileWallet(walletA)])
        try await waitForCampaigns(sut, userWalletId: walletA)

        #expect(loader.requestedWallets.count == 2)
    }

    @Test("A wallet still waiting for its answer does not hold back the campaigns of the others")
    func slowWalletDoesNotHoldBackOthers() async throws {
        let loader = CampaignsLoaderStub(gatedWalletIds: [walletA])
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA), mobileWallet(walletB)]), loader: loader)

        sut.initialize()

        #expect(try await waitForCampaigns(sut, userWalletId: walletB) == [CampaignsLoaderStub.campaign])
        #expect(currentCampaigns(sut, userWalletId: walletA).isEmpty)

        loader.openGate()

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
    }

    @Test("A wallet whose request fails does not take the other wallets' campaigns with it")
    func failingWalletDoesNotAffectOthers() async throws {
        let loader = CampaignsLoaderStub(failures: [walletA: .max])
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA), mobileWallet(walletB)]), loader: loader)

        sut.initialize()

        #expect(try await waitForCampaigns(sut, userWalletId: walletB) == [CampaignsLoaderStub.campaign])
        #expect(currentCampaigns(sut, userWalletId: walletA).isEmpty)
    }

    @Test("A wallet whose identity changes drops its campaigns and is asked about again")
    func walletWithChangedIdentityIsReloaded() async throws {
        let loader = CampaignsLoaderStub()
        let wallets = WalletsProviderStub([mobileWallet(walletA)])
        let sut = makeSUT(wallets: wallets, loader: loader)

        sut.initialize()
        try await waitForCampaigns(sut, userWalletId: walletA)

        wallets.set([cardWallet(walletA)])
        try await loader.waitForRequests(count: 2)

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
        #expect(loader.requestedWallets == [mobileWallet(walletA), cardWallet(walletA)])
    }

    @Test("A load that outlived the removal of its wallet does not overwrite the load started after the wallet came back")
    func staleLoadDoesNotOverrideCurrentLoad() async throws {
        let loader = CampaignsLoaderStub(failures: [walletA: 1], gatedWalletIds: [walletA], error: NonRetryableError.forbidden.error)
        let wallets = WalletsProviderStub([mobileWallet(walletA)])
        let sut = makeSUT(wallets: wallets, loader: loader)

        sut.initialize()
        try await loader.waitForRequests(count: 1)

        wallets.set([])
        wallets.set([mobileWallet(walletA)])
        try await loader.waitForRequests(count: 2)

        loader.openGate()

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
    }

    @Test("A transient failure is retried until the request succeeds")
    func transientFailureIsRetried() async throws {
        let loader = CampaignsLoaderStub(failures: [walletA: 2], error: Self.transportError(.timedOut))
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA)]), loader: loader, retryCount: 3)

        sut.initialize()

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
        #expect(loader.requestedWallets.count == 3)
    }

    @Test("Retries stop once they run out")
    func retriesAreBounded() async throws {
        let loader = CampaignsLoaderStub(failures: [walletA: .max], error: Self.transportError(.timedOut))
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA)]), loader: loader, retryCount: 2)

        sut.initialize()
        try await loader.waitForRequests(count: 3)
        try await Task.sleep(nanoseconds: Constants.settleInterval)

        #expect(loader.requestedWallets.count == 3)
        #expect(currentCampaigns(sut, userWalletId: walletA).isEmpty)
    }

    @Test(
        "A failure that would repeat on every attempt is not retried",
        arguments: [
            NonRetryableError.decoding,
            NonRetryableError.objectMapping,
            NonRetryableError.parameterEncoding,
            NonRetryableError.forbidden,
            NonRetryableError.unauthorized,
            NonRetryableError.badURL,
        ]
    )
    func permanentFailureIsNotRetried(error: NonRetryableError) async throws {
        let loader = CampaignsLoaderStub(failures: [walletA: .max], error: error.error)
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA)]), loader: loader, retryCount: 2)

        sut.initialize()
        try await loader.waitForRequests(count: 1)
        try await Task.sleep(nanoseconds: Constants.settleInterval)

        #expect(loader.requestedWallets.count == 1)
    }

    @Test("A server error is retried")
    func serverErrorIsRetried() async throws {
        let loader = CampaignsLoaderStub(failures: [walletA: 1], error: Self.statusCodeError(503))
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA)]), loader: loader, retryCount: 1)

        sut.initialize()

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
        #expect(loader.requestedWallets.count == 2)
    }

    @Test("A connection lost after a successful status is retried")
    func connectionLostAfterSuccessIsRetried() async throws {
        let error = MoyaError.underlying(AFError.sessionTaskFailed(error: URLError(.networkConnectionLost)), Response(statusCode: 200, data: Data()))
        let loader = CampaignsLoaderStub(failures: [walletA: 1], error: error)
        let sut = makeSUT(wallets: WalletsProviderStub([mobileWallet(walletA)]), loader: loader, retryCount: 1)

        sut.initialize()

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
        #expect(loader.requestedWallets.count == 2)
    }

    @Test("A wallet whose request failed is asked about again on the next change of the list")
    func failedWalletIsAskedAboutAgain() async throws {
        let loader = CampaignsLoaderStub(failures: [walletA: .max], error: NonRetryableError.forbidden.error)
        let wallets = WalletsProviderStub([mobileWallet(walletA)])
        let sut = makeSUT(wallets: wallets, loader: loader)

        sut.initialize()
        try await loader.waitForRequests(count: 1)
        try await Task.sleep(nanoseconds: Constants.settleInterval)

        loader.stopFailing()
        wallets.set([mobileWallet(walletA), mobileWallet(walletB)])

        #expect(try await waitForCampaigns(sut, userWalletId: walletA) == [CampaignsLoaderStub.campaign])
        #expect(loader.requestedWallets.filter { $0.userWalletId == walletA }.count == 2)
    }

    @Test("With promo campaigns unavailable nothing is requested at all")
    func disabledRequestsNothing() async throws {
        let loader = CampaignsLoaderStub()
        let wallets = WalletsProviderStub([mobileWallet(walletA)])
        let sut = makeSUT(wallets: wallets, loader: loader, isEnabled: false)

        sut.initialize()
        wallets.set([mobileWallet(walletA), mobileWallet(walletB)])
        try await Task.sleep(nanoseconds: Constants.settleInterval)

        #expect(loader.requestedWallets.isEmpty)
    }

    @Test("The mapper keeps the campaign identity, enrollment, content and payout tokens")
    func mapperKeepsIdentityAndEnrollment() throws {
        let json = """
        {
          "id": 42,
          "name": "summer_staking_2026",
          "alreadyEnrolled": true,
          "content": {
            "campaignName": "Summer staking bonus",
            "publicDescription": [{ "type": "text", "text": "Stake from 100 USDT" }],
            "actionButtonName": "Join"
          },
          "properties": {
            "payoutNeeded": true,
            "payoutTokens": [{ "tokenAddress": "0xdac17f958d2ee523a2206206994597c13d831ec7", "networkId": "ethereum", "tokenSymbol": "USDT", "tokenName": "Tether", "tokenId": "tether", "decimals": 6 }],
            "matchMode": "strict"
          }
        }
        """
        let dto = try JSONDecoder().decode(PromoCampaignsDTO.Promotion.self, from: Data(json.utf8))

        let campaign = PromoCampaignMapper().mapToPromoCampaign(from: dto)

        #expect(campaign.id == 42)
        #expect(campaign.name == "summer_staking_2026")
        #expect(campaign.isEnrolled)
        #expect(campaign.content.title == "Summer staking bonus")
        #expect(campaign.content.blocks == [.text("Stake from 100 USDT")])
        #expect(campaign.content.actionButtonTitle == "Join")
        #expect(campaign.isPayoutNeeded)
        #expect(campaign.payoutTokens == [
            CampaignEligibleToken(
                tokenId: "tether",
                tokenAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
                tokenSymbol: "USDT",
                tokenName: "Tether",
                networkId: "ethereum",
                decimals: 6
            ),
        ])
    }
}

// MARK: - Support

extension PromoCampaignsRepositoryTests {
    enum NonRetryableError: String, CustomTestStringConvertible {
        case decoding
        case objectMapping
        case parameterEncoding
        case forbidden
        case unauthorized
        case badURL

        var testDescription: String { rawValue }

        var error: any Error {
            switch self {
            case .decoding:
                return DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unexpected shape"))
            case .objectMapping:
                let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unexpected shape"))
                return MoyaError.objectMapping(decodingError, Response(statusCode: 200, data: Data()))
            case .parameterEncoding:
                return MoyaError.parameterEncoding(EncodingError.invalidValue("", .init(codingPath: [], debugDescription: "Unencodable")))
            case .forbidden:
                return PromoCampaignsRepositoryTests.statusCodeError(403)
            case .unauthorized:
                let validationError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
                let retryError = AFError.requestRetryFailed(retryError: validationError, originalError: validationError)
                return MoyaError.underlying(retryError, Response(statusCode: 401, data: Data()))
            case .badURL:
                return PromoCampaignsRepositoryTests.transportError(.badURL)
            }
        }
    }

    static func statusCodeError(_ statusCode: Int) -> MoyaError {
        let validationError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: statusCode))
        return MoyaError.underlying(validationError, Response(statusCode: statusCode, data: Data()))
    }

    static func transportError(_ code: URLError.Code) -> MoyaError {
        MoyaError.underlying(AFError.sessionTaskFailed(error: URLError(code)), nil)
    }
}

private extension PromoCampaignsRepositoryTests {
    enum Constants {
        static let pollAttempts = 250
        static let pollInterval: UInt64 = 20_000_000
        static let settleInterval: UInt64 = 200_000_000
        static let retryInterval: UInt64 = 10_000_000
    }

    func makeSUT(
        wallets: WalletsProviderStub,
        loader: CampaignsLoaderStub,
        isEnabled: Bool = true,
        retryCount: Int = 0
    ) -> PromoCampaignsRepository {
        PromoCampaignsRepository(
            walletsProvider: wallets,
            campaignsLoader: loader,
            isEnabled: { isEnabled },
            retryCount: retryCount,
            retryInterval: { _ in Constants.retryInterval }
        )
    }

    func mobileWallet(_ userWalletId: UserWalletId) -> PromoCampaignWallet {
        PromoCampaignWallet(userWalletId: userWalletId, identity: .mobile)
    }

    func cardWallet(_ userWalletId: UserWalletId) -> PromoCampaignWallet {
        PromoCampaignWallet(userWalletId: userWalletId, identity: .card(batchId: "AF04"))
    }

    func currentCampaigns(_ sut: PromoCampaignsRepository, userWalletId: UserWalletId) -> [PromoCampaign] {
        var campaigns: [PromoCampaign] = []
        let cancellable = sut.campaignsPublisher(for: userWalletId).sink { campaigns = $0 }
        cancellable.cancel()
        return campaigns
    }

    @discardableResult
    func waitForCampaigns(_ sut: PromoCampaignsRepository, userWalletId: UserWalletId) async throws -> [PromoCampaign] {
        try await waitUntil { currentCampaigns(sut, userWalletId: userWalletId).isNotEmpty }
        return currentCampaigns(sut, userWalletId: userWalletId)
    }

    func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0 ..< Constants.pollAttempts {
            if condition() {
                return
            }

            try await Task.sleep(nanoseconds: Constants.pollInterval)
        }

        Issue.record("Timed out waiting for the condition")
    }
}

private final class WalletsProviderStub: PromoCampaignWalletsProviding {
    private let walletsSubject: CurrentValueSubject<[PromoCampaignWallet], Never>

    init(_ wallets: [PromoCampaignWallet] = []) {
        walletsSubject = CurrentValueSubject(wallets)
    }

    var wallets: [PromoCampaignWallet] {
        walletsSubject.value
    }

    var walletsPublisher: AnyPublisher<[PromoCampaignWallet], Never> {
        walletsSubject.eraseToAnyPublisher()
    }

    func set(_ wallets: [PromoCampaignWallet]) {
        walletsSubject.send(wallets)
    }
}

private final class CampaignsLoaderStub: PromoCampaignsLoading {
    static let campaign = PromoCampaign(
        id: 42,
        name: "summer_staking_2026",
        isEnrolled: false,
        content: PromoCampaignContent(
            title: "Summer staking bonus",
            imageURL: nil,
            blocks: [],
            learnMoreLink: nil,
            termsLink: nil,
            actionButtonTitle: "Join"
        ),
        isPayoutNeeded: false,
        payoutTokens: []
    )

    private let error: any Error
    private let state: OSAllocatedUnfairLock<State>

    init(failures: [UserWalletId: Int] = [:], gatedWalletIds: Set<UserWalletId> = [], error: any Error = URLError(.timedOut)) {
        self.error = error
        state = OSAllocatedUnfairLock(initialState: State(failures: failures, gatedWalletIds: gatedWalletIds))
    }

    var requestedWallets: [PromoCampaignWallet] {
        state.withLock { $0.requestedWallets }
    }

    func loadPromoCampaigns(for wallet: PromoCampaignWallet) async throws -> [PromoCampaign] {
        let (isFailing, isGated) = state.withLock { state in
            state.requestedWallets.append(wallet)

            let remainingFailures = state.failures[wallet.userWalletId, default: 0]
            state.failures[wallet.userWalletId] = max(remainingFailures - 1, 0)

            return (remainingFailures > 0, state.gatedWalletIds.contains(wallet.userWalletId))
        }

        if isGated {
            await withCheckedContinuation { continuation in
                let resumeImmediately = state.withLock { state -> Bool in
                    guard state.gatedWalletIds.contains(wallet.userWalletId) else {
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

        if isFailing {
            throw error
        }

        return [Self.campaign]
    }

    func stopFailing() {
        state.withLock { $0.failures = [:] }
    }

    func openGate() {
        let waiters = state.withLock { state in
            state.gatedWalletIds = []
            defer { state.waiters = [] }
            return state.waiters
        }

        waiters.forEach { $0.resume() }
    }

    func waitForRequests(count: Int) async throws {
        for _ in 0 ..< 250 {
            if requestedWallets.count >= count {
                return
            }

            try await Task.sleep(nanoseconds: 20_000_000)
        }

        Issue.record("Expected \(count) requests, got \(requestedWallets.count)")
    }

    private struct State {
        var requestedWallets: [PromoCampaignWallet] = []
        var failures: [UserWalletId: Int]
        var gatedWalletIds: Set<UserWalletId>
        var waiters: [CheckedContinuation<Void, Never>] = []
    }
}
