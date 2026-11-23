//
//  PolymarketFastTradingRegistryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@MainActor
@Suite("Polymarket fast trading registry")
struct PolymarketFastTradingRegistryTests {
    @Test("Every screen of a wallet gets the same fast trading service")
    func walletKeepsItsService() throws {
        let (sut, _) = makeSUT()
        let wallet = UserWalletModelMock()

        let first = try #require(sut.context(for: wallet))
        let second = try #require(sut.context(for: wallet))

        #expect(first.service === second.service)
    }

    @Test("A deleted wallet loses its fast trading service while the other wallets keep theirs")
    func deletionDropsOnlyThatWallet() throws {
        let (sut, walletEvents) = makeSUT()
        let deleted = UserWalletModelMock()
        let kept = OtherWalletModelStub()
        let deletedService = try #require(sut.context(for: deleted)).service
        let keptService = try #require(sut.context(for: kept)).service

        walletEvents.send(.deleted(userWalletIds: [deleted.userWalletId], isRepositoryEmpty: false))

        #expect(try #require(sut.context(for: deleted)).service !== deletedService)
        #expect(try #require(sut.context(for: kept)).service === keptService)
    }

    @Test("Deleting a wallet stops the work of its fast trading service and leaves the other wallets' services at work")
    func deletionStopsTheDeletedWalletsWork() async throws {
        let (sut, walletEvents) = makeSUT()
        let deleted = UserWalletModelMock()
        let kept = OtherWalletModelStub()
        let deletedService = try #require(sut.context(for: deleted)?.service as? PolymarketFastTradingServiceSpy)
        let keptService = try #require(sut.context(for: kept)?.service as? PolymarketFastTradingServiceSpy)

        walletEvents.send(.deleted(userWalletIds: [deleted.userWalletId], isRepositoryEmpty: false))
        await Task { @MainActor in }.value

        #expect(deletedService.isWorkCancelled)
        #expect(!keptService.isWorkCancelled)
    }

    @Test("Locking the app keeps the work of the dropped fast trading services running")
    func lockKeepsTheWorkRunning() async throws {
        let (sut, walletEvents) = makeSUT()
        let service = try #require(sut.context(for: UserWalletModelMock())?.service as? PolymarketFastTradingServiceSpy)

        walletEvents.send(.locked)
        await Task { @MainActor in }.value

        #expect(!service.isWorkCancelled)
    }

    @Test("Locking the app drops the fast trading service of every wallet")
    func lockDropsEveryWallet() throws {
        let (sut, walletEvents) = makeSUT()
        let first = UserWalletModelMock()
        let second = OtherWalletModelStub()
        let firstService = try #require(sut.context(for: first)).service
        let secondService = try #require(sut.context(for: second)).service

        walletEvents.send(.locked)

        #expect(try #require(sut.context(for: first)).service !== firstService)
        #expect(try #require(sut.context(for: second)).service !== secondService)
    }

    @Test("A fast trading service built while its wallet is locked or deleted is not kept for the next screen", arguments: [false, true])
    func serviceBuiltAcrossALockIsNotKept(_ isDeletion: Bool) throws {
        let walletEvents = PassthroughSubject<UserWalletRepositoryEvent, Never>()
        let wallet = UserWalletModelMock()
        var builds = 0
        let sut = PolymarketFastTradingRegistry(
            walletEvents: walletEvents.eraseToAnyPublisher(),
            isAvailable: { true },
            makeContext: { _ in
                builds += 1

                if builds == 1 {
                    walletEvents.send(isDeletion ? .deleted(userWalletIds: [wallet.userWalletId], isRepositoryEmpty: false) : .locked)
                }

                return PolymarketFastTradingContext(signingRouter: PolymarketOrderSigningRouterSpy(), service: PolymarketFastTradingServiceSpy())
            }
        )

        let built = try #require(sut.context(for: wallet)).service
        let next = try #require(sut.context(for: wallet)).service

        #expect(built !== next)
    }

    @Test("Fast trading turned off gives a wallet no fast trading at all")
    func unavailableFastTradingGivesNothing() {
        let (sut, _) = makeSUT(isAvailable: false)

        #expect(sut.context(for: UserWalletModelMock()) == nil)
    }

    @Test("Building a wallet's fast trading may look up another wallet's on the way")
    func buildingAContextMayLookUpAnother() throws {
        let other = OtherWalletModelStub()
        weak var registry: PolymarketFastTradingRegistry?
        let sut = PolymarketFastTradingRegistry(
            walletEvents: .empty,
            isAvailable: { true },
            makeContext: { wallet in
                if wallet.userWalletId != other.userWalletId {
                    _ = registry?.context(for: other)
                }

                return PolymarketFastTradingContext(signingRouter: PolymarketOrderSigningRouterSpy(), service: PolymarketFastTradingServiceSpy())
            }
        )
        registry = sut

        let built = try #require(sut.context(for: UserWalletModelMock()))
        let otherService = try #require(sut.context(for: other)).service

        #expect(try #require(sut.context(for: UserWalletModelMock())).service === built.service)
        #expect(try #require(sut.context(for: other)).service === otherService)
    }
}

// MARK: - Helpers

private extension PolymarketFastTradingRegistryTests {
    func makeSUT(isAvailable: Bool = true) -> (sut: PolymarketFastTradingRegistry, walletEvents: PassthroughSubject<UserWalletRepositoryEvent, Never>) {
        let walletEvents = PassthroughSubject<UserWalletRepositoryEvent, Never>()
        let sut = PolymarketFastTradingRegistry(
            walletEvents: walletEvents.eraseToAnyPublisher(),
            isAvailable: { isAvailable },
            makeContext: { _ in
                PolymarketFastTradingContext(signingRouter: PolymarketOrderSigningRouterSpy(), service: PolymarketFastTradingServiceSpy())
            }
        )

        return (sut, walletEvents)
    }
}

// MARK: - Stubs

private final class OtherWalletModelStub: UserWalletModelMock {
    override var userWalletId: UserWalletId {
        UserWalletId(value: Data(repeating: 0x0f, count: 32))
    }
}
