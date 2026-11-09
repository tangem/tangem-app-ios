//
//  CollectiblesPendingPurchaseBannersViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesPendingPurchaseBannersViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesPendingPurchaseBannersViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesPendingPurchaseBannersViewModel
    typealias Banner = SUT.Banner

    @Test("An unfinished purchase shows the banner its status calls for, however long ago it was created", arguments: [
        (CollectiblesPurchaseStatus.waitingForPayment, 300.0, Banner.Kind?.some(.paymentInProgress)),
        (CollectiblesPurchaseStatus.waitingTxHash, 10.0, Banner.Kind?.some(.paymentInProgress)),
        (CollectiblesPurchaseStatus.packPurchased, 10.0, Banner.Kind?.some(.packToOpen)),
        (CollectiblesPurchaseStatus.packOpened, 10.0, Banner.Kind?.some(.packToOpen)),
        (CollectiblesPurchaseStatus.unknown("pack-stuck"), 10.0, Banner.Kind?.some(.packToOpen)),
        (CollectiblesPurchaseStatus.packOpeningError, 10.0, Banner.Kind?.none),
        (CollectiblesPurchaseStatus.paused, 10.0, Banner.Kind?.none),
    ])
    func showsBannerByStatus(status: CollectiblesPurchaseStatus, age: TimeInterval, kind: Banner.Kind?) async {
        let purchase = Self.purchase(txID: "tx-1", status: status, age: age)
        let (sut, _) = makeSUT(answers: [.purchases([purchase])])

        await sut.load()

        #expect(sut.banners == kind.map { [Banner(id: "tx-1", kind: $0)] } ?? [])
    }

    @Test("Banners go from the newest purchase to the oldest and leave out the one this device already delivered")
    func ordersNewestFirstWithoutDelivered() async {
        let purchases = [
            Self.purchase(txID: "old", status: .packPurchased, age: 300),
            Self.purchase(txID: "delivered", status: .packPurchased, age: 200),
            Self.purchase(txID: "new", status: .packPurchased, age: 100),
        ]
        let delivered = OSAllocatedUnfairLock<Set<String>>(initialState: ["delivered"])
        let (sut, _) = makeSUT(answers: [.purchases(purchases)], delivered: delivered)

        await sut.load()

        #expect(sut.banners == [Banner(id: "new", kind: .packToOpen), Banner(id: "old", kind: .packToOpen)])
    }

    @Test("A payment in progress is read again every 5 seconds until the backend moves it on")
    func paymentInProgressIsPolled() async {
        let paying = Self.purchase(txID: "tx-1", status: .waitingForPayment, age: 30)
        let paid = Self.purchase(txID: "tx-1", status: .packPurchased, age: 30)
        let (sut, delay) = makeSUT(answers: [.purchases([paying]), .purchases([paid])], isTimePassing: true)

        await sut.load()
        _ = await sut.$banners.values_.first { $0 == [Banner(id: "tx-1", kind: .packToOpen)] }

        #expect(delay.waits == [5])
    }

    @Test("A reload that fails still takes down the banner of a pack this device has just delivered")
    func failedReloadDropsDeliveredPack() async throws {
        let purchase = Self.purchase(txID: "tx-1", status: .packPurchased, age: 10)
        let delivered = OSAllocatedUnfairLock(initialState: Set<String>())
        let (sut, _) = makeSUT(answers: [.purchases([purchase]), .failure], delivered: delivered)

        await sut.load()
        try #require(sut.banners == [Banner(id: "tx-1", kind: .packToOpen)])

        delivered.withLock { $0.formUnion(["tx-1"]) }
        await sut.load()

        #expect(sut.banners.isEmpty)
    }

    @Test("An earlier load that answers after a later one does not overwrite the later banners")
    func staleLoadDoesNotOverwrite() async {
        let hold = PendingPurchaseProviderStub.Hold()
        let stale = Self.purchase(txID: "stale", status: .packPurchased, age: 20)
        let fresh = Self.purchase(txID: "fresh", status: .packPurchased, age: 10)
        let (sut, _) = makeSUT(answers: [.purchases([stale], hold: hold), .purchases([fresh])])

        let earlierLoad = Task { await sut.load() }
        await hold.started.wait()
        await sut.load()
        hold.release.open()
        await earlierLoad.value

        #expect(sut.banners == [Banner(id: "fresh", kind: .packToOpen)])
    }
}

// MARK: - Helpers

private extension CollectiblesPendingPurchaseBannersViewModelTests {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static func purchase(txID: String, status: CollectiblesPurchaseStatus, age: TimeInterval) -> CollectiblesPendingPurchase {
        CollectiblesPendingPurchase(
            txID: txID,
            machineID: "pokemon_50",
            status: status,
            createdAt: now.addingTimeInterval(-age),
            isTurboModeOn: false
        )
    }

    func makeSUT(
        answers: [PendingPurchaseProviderStub.Answer],
        delivered: OSAllocatedUnfairLock<Set<String>> = OSAllocatedUnfairLock(initialState: []),
        isTimePassing: Bool = false
    ) -> (SUT, DelaySpy) {
        let delay = DelaySpy(isTimePassing: isTimePassing)
        let sut = SUT(
            provider: PendingPurchaseProviderStub(answers: answers),
            isDelivered: { txID in delivered.withLock { $0.contains(txID) } },
            delayProvider: delay
        )

        return (trackForMemoryLeaks(sut), delay)
    }
}

// MARK: - Stubs

private final class PendingPurchaseProviderStub: CollectiblesPendingPurchaseProvider {
    struct Answer {
        let result: Result<[CollectiblesPendingPurchase], any Error>
        let hold: Hold?

        static var failure: Answer {
            Answer(result: .failure(URLError(.notConnectedToInternet)), hold: nil)
        }

        static func purchases(_ purchases: [CollectiblesPendingPurchase], hold: Hold? = nil) -> Answer {
            Answer(result: .success(purchases), hold: hold)
        }
    }

    struct Hold {
        let started = TestGate()
        let release = TestGate()
    }

    private let answers: [Answer]
    private let callsCount = OSAllocatedUnfairLock(initialState: 0)

    init(answers: [Answer]) {
        self.answers = answers
    }

    func load() async throws -> [CollectiblesPendingPurchase] {
        let index = callsCount.withLock { count -> Int in
            defer { count += 1 }
            return count
        }
        let answer = answers[min(index, answers.count - 1)]

        if let hold = answer.hold {
            hold.started.open()
            await hold.release.wait()
        }

        return try answer.result.get()
    }
}

private final class DelaySpy: PollDelayProvider {
    private let recordedWaits = OSAllocatedUnfairLock<[TimeInterval]>(initialState: [])
    private let isTimePassing: Bool

    init(isTimePassing: Bool) {
        self.isTimePassing = isTimePassing
    }

    var waits: [TimeInterval] {
        recordedWaits.withLock { $0 }
    }

    func wait(for seconds: TimeInterval) async throws {
        recordedWaits.withLock { $0.append(seconds) }

        guard isTimePassing else {
            let neverEnding = AsyncStream<Void> { _ in }
            for await _ in neverEnding {}
            throw CancellationError()
        }
    }
}
