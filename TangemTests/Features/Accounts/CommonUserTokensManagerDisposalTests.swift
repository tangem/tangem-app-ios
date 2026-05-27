//
//  CommonUserTokensManagerDisposalTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import TangemSdk
import TangemFoundation
@testable import Tangem

@Suite("Tests for `CommonUserTokensManager` disposal behavior")
struct CommonUserTokensManagerDisposalTests {
    // MARK: - Publisher termination

    @Test("`userTokensPublisher` finishes after `dispose()`")
    func userTokensPublisherFinishesAfterDispose() throws {
        let sut = try makeSUT()
        var cancellables = Set<AnyCancellable>()
        var completion: Subscribers.Completion<Never>?

        sut.userTokensPublisher
            .sink(receiveCompletion: { completion = $0 }, receiveValue: { _ in })
            .store(in: &cancellables)

        sut.dispose()

        #expect(completion != nil)
    }

    @Test("`orderedWalletModelIds` finishes after `dispose()`")
    func orderedWalletModelIdsFinishesAfterDispose() throws {
        let sut = try makeSUT()
        var cancellables = Set<AnyCancellable>()
        var completion: Subscribers.Completion<Never>?

        sut.orderedWalletModelIds
            .sink(receiveCompletion: { completion = $0 }, receiveValue: { _ in })
            .store(in: &cancellables)

        sut.dispose()

        #expect(completion != nil)
    }

    @Test("`groupingOptionPublisher` finishes after `dispose()`")
    func groupingOptionPublisherFinishesAfterDispose() throws {
        let sut = try makeSUT()
        var cancellables = Set<AnyCancellable>()
        var completion: Subscribers.Completion<Never>?

        sut.groupingOptionPublisher
            .sink(receiveCompletion: { completion = $0 }, receiveValue: { _ in })
            .store(in: &cancellables)

        sut.dispose()

        #expect(completion != nil)
    }

    @Test("`sortingOptionPublisher` finishes after `dispose()`")
    func sortingOptionPublisherFinishesAfterDispose() throws {
        let sut = try makeSUT()
        var cancellables = Set<AnyCancellable>()
        var completion: Subscribers.Completion<Never>?

        sut.sortingOptionPublisher
            .sink(receiveCompletion: { completion = $0 }, receiveValue: { _ in })
            .store(in: &cancellables)

        sut.dispose()

        #expect(completion != nil)
    }

    // MARK: - `sync(completion:)` behavior around disposal

    @Test("`sync(completion:)` invokes the completion immediately when called after `dispose()`")
    func syncAfterDisposeFiresCompletionImmediately() throws {
        let sut = try makeSUT()
        var fired = false

        sut.dispose()
        sut.sync { fired = true }

        #expect(fired)
    }

    @Test("`sync(completion:)` invokes the registered completion exactly once when `dispose()` runs mid-sync")
    func syncCompletionFiresExactlyOnceOnDispose() async throws {
        let sut = try makeSUT()
        let counter = OSAllocatedUnfairLock(initialState: 0)

        sut.sync { counter.withLock { $0 += 1 } }
        sut.dispose()

        // Allow the unstructured `Task` scheduled inside `handleUserTokensSync()`
        // to be picked up by the global executor. The asserted property —
        // "the completion fires exactly once" — holds regardless of whether
        // `dispose()` or that `Task` drains `pendingCompletions` first.
        try await Task.sleep(for: .milliseconds(1000))

        #expect(counter.withLock { $0 == 1 })
    }

    // MARK: - Helpers

    private func makeSUT() throws -> CommonUserTokensManager {
        let userWalletId = UserWalletId(value: .randomData(count: 32))
        let config = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let account = StoredCryptoAccount(
            config: config,
            tokenListAppearance: .default,
            tokens: []
        )
        let repository = UserTokensRepositoryStub(cryptoAccount: account)
        let derivationInfo = CommonUserTokensManager.DerivationInfo(
            derivationIndex: AccountModelUtils.mainAccountDerivationIndex,
            derivationStyle: .v3
        )

        return CommonUserTokensManager(
            userWalletId: userWalletId,
            userTokensRepository: repository,
            derivationInfo: derivationInfo,
            existingCurves: EllipticCurve.allCases,
            persistentBlockchains: [],
            shouldLoadExpressAvailability: false,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: UserWalletConfigStubs.walletV2Stub)
        )
    }
}
