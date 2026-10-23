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
    @Test("Pending reports are sent oldest first")
    func pendingReportsAreSentOldestFirst() async throws {
        let environment = DeliveryEnvironment(userWalletIds: [Constants.firstWalletId, Constants.secondWalletId, Constants.thirdWalletId])

        try await environment.run {
            try await environment.repository.waitUntilDrained()
        }

        #expect(environment.attemptedWalletIds == [Constants.firstWalletId, Constants.secondWalletId, Constants.thirdWalletId])
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
    }
}

// MARK: - Helpers

private extension CommonWalletCardsBackupReportServiceTests {
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

    var attemptedWalletIds: [String] {
        attempts.value
    }

    init(userWalletIds: [String], firstAttemptStatusCode: Int? = nil) {
        repository = WalletCardsBackupReportRepositoryStub(
            pendingReports: userWalletIds.map {
                WalletCardsWaitingDeliveryBackupCards(id: UUID(), userWalletId: $0, isImported: false, cards: [])
            }
        )

        apiService.saveWalletCardsHandler = { [attempts] userWalletId, _ in
            attempts.send(attempts.value + [userWalletId])

            if let firstAttemptStatusCode, attempts.value.count == 1 {
                throw MoyaError.statusCode(Response(statusCode: firstAttemptStatusCode, data: Data()))
            }
        }
    }

    func run(_ operation: () async throws -> Void) async throws {
        try await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.walletCardsBackupReportRepository]
            let previousApiService = InjectedValues[\.tangemApiService]
            InjectedValues[\.walletCardsBackupReportRepository] = repository
            InjectedValues[\.tangemApiService] = apiService
            defer {
                InjectedValues[\.walletCardsBackupReportRepository] = previousRepository
                InjectedValues[\.tangemApiService] = previousApiService
            }

            let service = CommonWalletCardsBackupReportService(reachabilityProvider: reachabilityProvider)
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

    init(pendingReports: [WalletCardsWaitingDeliveryBackupCards]) {
        self.pendingReports = CurrentValueSubject(pendingReports)
    }

    var pendingReportsPublisher: AnyPublisher<[WalletCardsWaitingDeliveryBackupCards], Never> {
        pendingReports.eraseToAnyPublisher()
    }

    var oldestPendingReport: WalletCardsWaitingDeliveryBackupCards? {
        guard let oldest = pendingReports.value.first else {
            isDrained.send(true)
            return nil
        }

        return oldest
    }

    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?) {}

    func removePendingReport(_ report: WalletCardsWaitingDeliveryBackupCards) {
        pendingReports.send(pendingReports.value.filter { $0.id != report.id })
    }

    func waitUntilDrained() async throws {
        _ = try await isDrained.first { $0 }.async()
    }
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
