//
//  CommonWalletCardsBackupReportServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import Testing
import TangemSdk
import TangemFoundation
import TangemNetworkUtils
@testable import Tangem

@Suite("CommonWalletCardsBackupReportService", .timeLimit(.minutes(1)))
struct CommonWalletCardsBackupReportServiceTests {
    @Test("A queued card with an unknown role is sent without inventing a primary role")
    func queuedUnknownRoleIsOmitted() async throws {
        let card = WalletCardsBackupCard(
            cardId: "AC01000000000001",
            cardPublicKey: Data(repeating: 0x02, count: 33),
            identity: .filled(userWalletId: Constants.firstWalletId, isImported: false),
            role: nil,
            backupStatus: .cardLinked,
            curves: [.secp256k1],
            errorCode: nil,
            errorMessage: nil
        )
        let environment = DeliveryEnvironment(userWalletIds: [Constants.firstWalletId], cards: [card])

        try await environment.run {
            try await environment.repository.waitUntilDrained()
        }

        let request = try #require(environment.sentRequests.first)
        let data = try JSONEncoder().encode(request)
        let body = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cards = try #require(body["cards"] as? [[String: Any]])
        let sentCard = try #require(cards.first)
        #expect(sentCard["role"] == nil)
        #expect(sentCard["backupStatus"] as? String == "cardLinked")
    }

    @Test("Pending reports are sent oldest first")
    func pendingReportsAreSentOldestFirst() async throws {
        let environment = DeliveryEnvironment(userWalletIds: [Constants.firstWalletId, Constants.secondWalletId, Constants.thirdWalletId])

        try await environment.run {
            try await environment.repository.waitUntilDrained()
        }

        #expect(environment.attemptedWalletIds == [Constants.firstWalletId, Constants.secondWalletId, Constants.thirdWalletId])
        #expect(environment.repository.deliveryResults == [true, true, true])
    }

    @Test("A report postponed by a retryable status stays at the head until the next attempt", arguments: [500, 503, 408, 429])
    func postponedReportStaysAtTheHead(statusCode: Int) async throws {
        let environment = DeliveryEnvironment(
            userWalletIds: [Constants.firstWalletId, Constants.secondWalletId],
            firstAttemptStatusCode: statusCode
        )

        try await environment.run {
            try await environment.waitForAttempts(count: 1)
            environment.reachabilityProvider.reconnect()
            try await environment.repository.waitUntilDrained()
        }

        #expect(environment.attemptedWalletIds == [Constants.firstWalletId, Constants.firstWalletId, Constants.secondWalletId])
    }

    @Test("A report refused with a client error is dropped and the rest are sent", arguments: [400, 403, 404])
    func refusedReportIsDropped(statusCode: Int) async throws {
        let environment = DeliveryEnvironment(
            userWalletIds: [Constants.firstWalletId, Constants.secondWalletId],
            firstAttemptStatusCode: statusCode
        )

        try await environment.run {
            try await environment.repository.waitUntilDrained()
        }

        #expect(environment.attemptedWalletIds == [Constants.firstWalletId, Constants.secondWalletId])
        #expect(environment.repository.deliveryResults == [false, true])
    }

    @Test("Reconnecting retries a failed initial load even while the queue publisher is empty")
    func reconnectRetriesInitialLoadFailure() async throws {
        let environment = DeliveryEnvironment(userWalletIds: [Constants.firstWalletId])
        environment.repository.simulatesInitialReadFailure = true
        try await environment.run {
            try await environment.repository.waitForInitialReadFailure()
            #expect(environment.attemptedWalletIds.isEmpty)
            environment.reachabilityProvider.reconnect()
            try await environment.repository.waitUntilDrained()
        }
        #expect(environment.attemptedWalletIds == [Constants.firstWalletId])
    }

    @Test("Delivered JSON omits an unknown role and preserves known roles", arguments: [
        (nil, nil), (.primary, "primary"), (.backup(index: 2), "backup2"),
    ] as [(WalletCardsBackupCard.Role?, String?)])
    func deliveredJSONPreservesRole(role: WalletCardsBackupCard.Role?, expectedRole: String?) async throws {
        let card = WalletCardsBackupCard(
            cardId: "AC01000000000001",
            cardPublicKey: Data(repeating: 0x02, count: 33),
            identity: .filled(userWalletId: Constants.firstWalletId, isImported: false),
            role: role,
            backupStatus: .cardLinked,
            curves: [.secp256k1],
            errorCode: nil,
            errorMessage: nil
        )
        let environment = DeliveryEnvironment(userWalletIds: [Constants.firstWalletId], cards: [card])
        try await environment.run {
            try await environment.repository.waitUntilDrained()
        }
        let request = try #require(environment.sentRequests.first)
        let data = try JSONEncoder().encode(request)
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cards = try #require(body["cards"] as? [[String: Any]])
        let sent = try #require(cards.first)
        #expect(sent["role"] as? String == expectedRole)
        if expectedRole == nil {
            #expect(sent["role"] == nil)
        }
        #expect(sent["backupStatus"] as? String == "cardLinked")
    }

    @Test("A saved problematic card is observed without another NFC scan")
    func reportsSavedCardOnInitialization() async throws {
        try await withLoginEnvironment { wallets, repository in
            wallets.models = [makeSavedWallet()]
            let service = CommonWalletCardsBackupReportService(reportsPreviouslySavedWallets: true)
            service.initialize()
            await drainMainQueue()

            let card = try #require(repository.observedSavedCards.first)
            #expect(card.backupStatus == .cardLinked)
            #expect(card.role == nil)
            #expect(repository.observedSavedCards.count == 1)
            withExtendedLifetime(service) {}
        }
    }

    @Test("Unlocking reports every saved wallet that was unavailable at launch")
    func unlockReportsSavedWallets() async throws {
        try await withLoginEnvironment { wallets, repository in
            let service = CommonWalletCardsBackupReportService(reportsPreviouslySavedWallets: true)
            service.initialize()
            await drainMainQueue()
            #expect(repository.observedSavedCards.isEmpty)

            wallets.models = [makeSavedWallet(id: 0xAA), makeSavedWallet(id: 0xBB)]
            wallets.emit(.unlocked)
            await drainMainQueue()
            #expect(repository.observedSavedCards.count == 2)
            wallets.emit(.locked)
            await drainMainQueue()
            #expect(repository.observedSavedCards.count == 2)
            withExtendedLifetime(service) {}
        }
    }

    @Test("Locked and active cards are not reported on sign-in", arguments: [true, false])
    func ignoresIneligibleSavedWallet(isLocked: Bool) async throws {
        try await withLoginEnvironment { wallets, repository in
            wallets.models = [makeSavedWallet(isLocked: isLocked, status: isLocked ? .cardLinked(cardsCount: 2) : .active(cardsCount: 2))]
            let service = CommonWalletCardsBackupReportService(reportsPreviouslySavedWallets: true)
            service.initialize()
            await drainMainQueue()
            #expect(repository.observedSavedCards.isEmpty)
            withExtendedLifetime(service) {}
        }
    }

    @Test("The sign-in trigger sends nothing while its toggle is disabled")
    func disabledLoginTriggerDoesNothing() async throws {
        try await withLoginEnvironment { wallets, repository in
            wallets.models = [makeSavedWallet()]
            let service = CommonWalletCardsBackupReportService(reportsPreviouslySavedWallets: false)
            service.initialize()
            wallets.emit(.unlocked)
            await drainMainQueue()
            #expect(repository.observedSavedCards.isEmpty)
            withExtendedLifetime(service) {}
        }
    }
}

// MARK: - Helpers

private extension CommonWalletCardsBackupReportServiceTests {
    func withLoginEnvironment(
        _ operation: (LoginUserWalletRepositoryStub, WalletCardsBackupReportRepositoryStub) async throws -> Void
    ) async throws {
        try await InjectedDependenciesIsolation.shared.run {
            let wallets = LoginUserWalletRepositoryStub(models: [])
            let repository = WalletCardsBackupReportRepositoryStub(pendingReports: [])
            let previousWallets = InjectedValues[\.userWalletRepository]
            let previousReports = InjectedValues[\.walletCardsBackupReportRepository]
            InjectedValues[\.userWalletRepository] = wallets
            InjectedValues[\.walletCardsBackupReportRepository] = repository
            defer {
                InjectedValues[\.userWalletRepository] = previousWallets
                InjectedValues[\.walletCardsBackupReportRepository] = previousReports
            }
            try await operation(wallets, repository)
        }
    }

    func makeSavedWallet(
        id: UInt8 = 0xAA,
        isLocked: Bool = false,
        status: Card.BackupStatus = .cardLinked(cardsCount: 2)
    ) -> UserWalletModel {
        var card = CardDTO(card: CardMock.wallet2.card)
        card.backupStatus = status
        return LoginUserWalletModelStub(
            userWalletName: "Wallet",
            isUserWalletLocked: isLocked,
            isDelayed: false,
            cardsCount: 2,
            userWalletId: UserWalletId(value: Data([id])),
            walletManagers: [],
            config: Wallet2Config(card: card, isDemo: false)
        )
    }

    func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    enum Constants {
        static let firstWalletId = "wallet-a"
        static let secondWalletId = "wallet-b"
        static let thirdWalletId = "wallet-c"
    }
}

// MARK: - DeliveryEnvironment

private final class DeliveryEnvironment {
    let repository: WalletCardsBackupReportRepositoryStub
    let reachabilityProvider = NetworkReachabilityProviderStub()

    private let apiService = FakeTangemApiService()
    private let attempts = CurrentValueSubject<[String], Never>([])
    private let requests = CurrentValueSubject<[WalletCardsDTO.Request], Never>([])

    var attemptedWalletIds: [String] {
        attempts.value
    }

    var sentRequests: [WalletCardsDTO.Request] {
        requests.value
    }

    init(userWalletIds: [String], firstAttemptStatusCode: Int? = nil, cards: [WalletCardsBackupCard] = []) {
        repository = WalletCardsBackupReportRepositoryStub(
            pendingReports: userWalletIds.map {
                WalletCardsWaitingDeliveryBackupCards(id: UUID(), userWalletId: $0, isImported: false, cards: cards)
            }
        )

        apiService.saveWalletCardsHandler = { [attempts, requests] userWalletId, request in
            attempts.send(attempts.value + [userWalletId])
            requests.send(requests.value + [request])

            if let firstAttemptStatusCode, attempts.value.count == 1 {
                throw MoyaError.statusCode(Response(statusCode: firstAttemptStatusCode, data: Data()))
            }
        }
    }

    func run(_ operation: () async throws -> Void) async throws {
        try await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.walletCardsBackupReportRepository]
            let previousApiService = InjectedValues[\.tangemApiService]
            let previousWallets = InjectedValues[\.userWalletRepository]
            InjectedValues[\.walletCardsBackupReportRepository] = repository
            InjectedValues[\.tangemApiService] = apiService
            InjectedValues[\.userWalletRepository] = LoginUserWalletRepositoryStub(models: [])
            defer {
                InjectedValues[\.walletCardsBackupReportRepository] = previousRepository
                InjectedValues[\.tangemApiService] = previousApiService
                InjectedValues[\.userWalletRepository] = previousWallets
            }

            let service = CommonWalletCardsBackupReportService(reachabilityProvider: reachabilityProvider, reportsPreviouslySavedWallets: false)
            service.initialize()

            try await operation()

            withExtendedLifetime(service) {}
        }
    }

    func waitForAttempts(count: Int) async throws {
        _ = try await attempts.first { $0.count >= count }.async()
    }
}

// MARK: - Stubs

private final class WalletCardsBackupReportRepositoryStub: WalletCardsBackupReportRepository {
    private let pendingReports: CurrentValueSubject<[WalletCardsWaitingDeliveryBackupCards], Never>
    private let isDrained = CurrentValueSubject<Bool, Never>(false)
    private let observedCards = CurrentValueSubject<[WalletCardsCurrentlyProcessedCard], Never>([])
    private let results = CurrentValueSubject<[Bool], Never>([])
    private let initialReadFailed = CurrentValueSubject<Bool, Never>(false)

    var simulatesInitialReadFailure = false

    var observedSavedCards: [WalletCardsCurrentlyProcessedCard] { observedCards.value }
    var deliveryResults: [Bool] { results.value }

    init(pendingReports: [WalletCardsWaitingDeliveryBackupCards]) {
        self.pendingReports = CurrentValueSubject(pendingReports)
    }

    var pendingReportsPublisher: AnyPublisher<[WalletCardsWaitingDeliveryBackupCards], Never> {
        if simulatesInitialReadFailure {
            return Just([]).eraseToAnyPublisher()
        }
        return pendingReports.eraseToAnyPublisher()
    }

    var oldestPendingReport: WalletCardsWaitingDeliveryBackupCards? {
        if simulatesInitialReadFailure, !initialReadFailed.value {
            initialReadFailed.send(true)
            return nil
        }
        guard let oldest = pendingReports.value.first else {
            isDrained.send(true)
            return nil
        }

        return oldest
    }

    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?) {}
    func storePreviouslySavedCardIfNeeded(_ card: WalletCardsCurrentlyProcessedCard) {
        observedCards.send(observedCards.value + [card])
    }

    func removePendingReport(_ report: WalletCardsWaitingDeliveryBackupCards, wasDelivered: Bool) {
        results.send(results.value + [wasDelivered])
        pendingReports.send(pendingReports.value.filter { $0.id != report.id })
    }

    func waitForInitialReadFailure() async throws {
        _ = try await initialReadFailed.first { $0 }.async()
    }

    func waitUntilDrained() async throws {
        _ = try await isDrained.first { $0 }.async()
    }
}

private final class LoginUserWalletRepositoryStub: FakeUserWalletRepository {
    private let events = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    override var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { events.eraseToAnyPublisher() }

    func emit(_ event: UserWalletRepositoryEvent) { events.send(event) }
}

private final class LoginUserWalletModelStub: FakeUserWalletModel {
    override var backupState: UserWalletBackupState { .incompleteBackup }
}

private final class NetworkReachabilityProviderStub: NetworkReachabilityProvider, @unchecked Sendable {
    private let subject = CurrentValueSubject<Bool, Never>(true)

    var isReachable: Bool {
        subject.value
    }

    var isReachablePublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func reconnect() {
        subject.send(false)
        subject.send(true)
    }
}
