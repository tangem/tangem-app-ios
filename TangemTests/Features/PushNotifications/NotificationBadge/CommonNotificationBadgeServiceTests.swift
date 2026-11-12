//
//  CommonNotificationBadgeServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import UIKit
import TangemFoundation
import TangemTestKit
@testable import Tangem

@Suite("Notification badge service", .timeLimit(.minutes(1)))
final class CommonNotificationBadgeServiceTests: LeakTrackingTestSuite {
    @Test("On start the badge shows the sum over every wallet")
    func startAppliesSumOverWallets() async {
        let repository = UserWalletRepositoryStub(models: [
            BadgeUserWalletModelStub(count: 1),
            BadgeUserWalletModelStub(count: 2),
        ])

        await withService(repository: repository) { applier, _ in
            var applied = applier.appliedCounts.makeAsyncIterator()

            #expect(await applied.next() == 3)
        }
    }

    @Test("A wallet added later joins the sum")
    func insertedWalletJoinsSum() async {
        let first = BadgeUserWalletModelStub(count: 1)
        let repository = UserWalletRepositoryStub(models: [first])

        await withService(repository: repository) { applier, _ in
            var applied = applier.appliedCounts.makeAsyncIterator()
            #expect(await applied.next() == 1)

            repository.models = [first, BadgeUserWalletModelStub(count: 2)]
            repository.emit(.inserted(userWalletId: UserWalletId(value: Data([0xBB]))))

            #expect(await applied.next() == 3)
        }
    }

    @Test("Deleting the last wallet clears the badge")
    func deletingLastWalletClearsBadge() async {
        let repository = UserWalletRepositoryStub(models: [BadgeUserWalletModelStub(count: 2)])

        await withService(repository: repository) { applier, _ in
            var applied = applier.appliedCounts.makeAsyncIterator()
            #expect(await applied.next() == 2)

            repository.models = []
            repository.emit(.deleted(userWalletIds: [UserWalletId(value: Data([0xAA]))], isRepositoryEmpty: true))

            #expect(await applied.next() == 0)
        }
    }

    @Test("A wallet that hasn't given its count yet counts as zero instead of holding the others back")
    func silentWalletCountsAsZero() async {
        let repository = UserWalletRepositoryStub(models: [
            BadgeUserWalletModelStub(count: 1),
            BadgeUserWalletModelStub(count: nil),
        ])

        await withService(repository: repository) { applier, _ in
            var applied = applier.appliedCounts.makeAsyncIterator()

            #expect(await applied.next() == 1)
        }
    }

    @Test("Before the wallets are loaded the badge is left as it is")
    func noWalletsLeaveBadge() async {
        let repository = UserWalletRepositoryStub(models: [])

        await withService(repository: repository) { applier, _ in
            var applied = applier.appliedCounts.makeAsyncIterator()

            repository.models = [BadgeUserWalletModelStub(count: 2)]
            repository.emit(.unlocked)

            #expect(await applied.next() == 2)
        }
    }

    @Test("The first wallet added to an empty unlocked app is followed")
    func firstWalletInEmptyAppIsFollowed() async {
        let repository = UserWalletRepositoryStub(models: [])

        await withService(repository: repository) { applier, _ in
            var applied = applier.appliedCounts.makeAsyncIterator()

            repository.emit(.unlocked)
            await MainActor.run {}

            repository.models = [BadgeUserWalletModelStub(count: 2)]
            repository.emit(.selected(userWalletId: UserWalletId(value: Data([0xAA]))))

            #expect(await applied.next() == 2)
        }
    }

    @Test("Locking stops following the wallets")
    func lockingStopsFollowingWallets() async {
        let wallet = BadgeUserWalletModelStub(count: 1)
        let repository = UserWalletRepositoryStub(models: [wallet])

        await withService(repository: repository) { applier, _ in
            var applied = applier.appliedCounts.makeAsyncIterator()
            var cancellations = wallet.cancellations.makeAsyncIterator()
            #expect(await applied.next() == 1)

            repository.emit(.locked)

            #expect(await cancellations.next() != nil)
        }
    }

    @Test("Coming back to the app applies the sum again even when it hasn't changed")
    func activationReappliesUnchangedSum() async {
        let repository = UserWalletRepositoryStub(models: [BadgeUserWalletModelStub(count: 2)])

        await withService(repository: repository) { applier, notificationCenter in
            var applied = applier.appliedCounts.makeAsyncIterator()
            #expect(await applied.next() == 2)

            notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

            #expect(await applied.next() == 2)
        }
    }
}

// MARK: - Helpers

private extension CommonNotificationBadgeServiceTests {
    func withService(
        repository: UserWalletRepositoryStub,
        operation: (_ applier: NotificationBadgeApplierSpy, _ notificationCenter: NotificationCenter) async -> Void
    ) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousUserWalletRepository = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = repository

            defer {
                InjectedValues[\.userWalletRepository] = previousUserWalletRepository
            }

            let applier = NotificationBadgeApplierSpy()
            let notificationCenter = NotificationCenter()
            let service = trackForMemoryLeaks(
                CommonNotificationBadgeService(applier: applier, notificationCenter: notificationCenter, debounceInterval: .zero)
            )

            await MainActor.run { service.initialize() }
            await operation(applier, notificationCenter)
            await MainActor.run {}
            withExtendedLifetime(service) {}
        }
    }
}

// MARK: - Stubs

private final class NotificationBadgeApplierSpy: NotificationBadgeApplier {
    let appliedCounts: AsyncStream<Int>
    private let appliedCountsContinuation: AsyncStream<Int>.Continuation

    init() {
        (appliedCounts, appliedCountsContinuation) = AsyncStream.makeStream()
    }

    func apply(count: Int) {
        appliedCountsContinuation.yield(count)
    }
}

private final class UserWalletRepositoryStub: FakeUserWalletRepository {
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    override var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func emit(_ event: UserWalletRepositoryEvent) {
        eventSubject.send(event)
    }
}

private final class BadgeUserWalletModelStub: UserWalletModelMock {
    let cancellations: AsyncStream<Void>
    private let cancellationsContinuation: AsyncStream<Void>.Continuation
    private let countSubject: CurrentValueSubject<Int?, Never>

    init(count: Int?) {
        countSubject = CurrentValueSubject(count)
        (cancellations, cancellationsContinuation) = AsyncStream.makeStream()
    }

    override var notificationBadgeCountPublisher: AnyPublisher<Int, Never> {
        countSubject
            .compactMap { $0 }
            .handleEvents(receiveCancel: { [cancellationsContinuation] in
                cancellationsContinuation.yield()
            })
            .eraseToAnyPublisher()
    }

    func send(_ count: Int) {
        countSubject.send(count)
    }
}
