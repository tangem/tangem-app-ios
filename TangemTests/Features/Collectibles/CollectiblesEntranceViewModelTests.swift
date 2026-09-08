//
//  CollectiblesEntranceViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemTestKit
import TangemUI
@testable import Tangem

@Suite("CollectiblesEntranceViewModel")
@MainActor
final class CollectiblesEntranceViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesEntranceViewModel

    // MARK: - Single wallet

    @Test("Opens the main screen when the account exists")
    func opensMainWhenAccountExists() async {
        let sut = makeSUT(wallets: [WalletStub("A")], accountStatus: .success(.exists))

        let options = await open(sut)

        #expect(options?.destination == .main)
    }

    @Test("Opens the welcome screen when there is no account")
    func opensWelcomeWhenNoAccount() async {
        let sut = makeSUT(wallets: [WalletStub("A")], accountStatus: .success(.missing))

        let options = await open(sut)

        #expect(options?.destination == .welcome)
    }

    @Test("Opens nothing when the status request fails")
    func opensNothingOnFailure() async {
        let sut = makeSUT(wallets: [WalletStub("A")], accountStatus: .failure(StubError.requested))

        let options = await open(sut)

        #expect(options == nil)
    }

    @Test("Opens nothing without wallets")
    func opensNothingWithoutWallets() async {
        let sut = makeSUT(wallets: [], accountStatus: .success(.exists))

        let options = await open(sut)

        #expect(options == nil)
        #expect(sut.openingTask == nil)
    }

    @Test("Ignores repeated taps while the request is in flight")
    func ignoresRepeatedTapsWhileResolving() async {
        let provider = AccountStatusProviderStub(result: .success(.exists))
        let sut = makeSUT(wallets: [WalletStub("A")], provider: provider)

        var openCount = 0
        sut.openCollectibles { _ in openCount += 1 }
        sut.openCollectibles { _ in openCount += 1 }
        await sut.openingTask?.value

        #expect(provider.loadCallCount == 1)
        #expect(openCount == 1)
    }

    @Test("Cancels the pending request when the card leaves the screen")
    func cancelsPendingRequestOnDeinit() async {
        var opened = false
        var sut: SUT? = makeSUT(wallets: [WalletStub("A")], provider: HangingAccountStatusProviderStub())

        sut?.openCollectibles { _ in opened = true }
        let task = sut?.openingTask
        sut = nil
        await task?.value

        #expect(!opened)
    }

    // MARK: - Multiple wallets

    @Test("Shows the wallet selector instead of loading the status")
    func showsSelectorForMultipleWallets() async {
        let provider = AccountStatusProviderStub(result: .success(.exists))
        let presenter = FloatingSheetPresenterSpy()
        let sut = makeSUT(wallets: [WalletStub("A"), WalletStub("B")], provider: provider, presenter: presenter)

        sut.openCollectibles { _ in }
        await presenter.waitForSheets(count: 1)

        #expect(presenter.enqueuedSheets.first is CollectiblesWalletSelectorViewModel)
        #expect(provider.loadCallCount == 0)
    }

    @Test("Selecting a wallet resolves the destination")
    func selectingWalletResolvesDestination() async throws {
        let presenter = FloatingSheetPresenterSpy()
        let sut = makeSUT(
            wallets: [WalletStub("A"), WalletStub("B")],
            accountStatus: .success(.exists),
            presenter: presenter
        )

        var options: CollectiblesCoordinator.Options?
        sut.openCollectibles { options = $0 }
        await presenter.waitForSheets(count: 1)

        let sheet = try #require(presenter.enqueuedSheets.first as? CollectiblesWalletSelectorViewModel)
        let selector = sheet.accountSelectorViewModel
        await drainMainQueue()

        let walletItem = try #require(selector.walletItems.first)
        selector.handleViewAction(.selectItem(.wallet(walletItem)))
        await sut.openingTask?.value

        #expect(options?.destination == .main)
    }
}

// MARK: - Helpers

private extension CollectiblesEntranceViewModelTests {
    func makeSUT(
        wallets: [UserWalletModel],
        accountStatus: Result<CollectiblesAccountStatus, Error> = .success(.exists),
        provider: (any CollectiblesAccountStatusProvider)? = nil,
        presenter: FloatingSheetPresenterSpy? = nil
    ) -> SUT {
        let viewModel = SUT(
            accountStatusProvider: provider ?? AccountStatusProviderStub(result: accountStatus),
            userWalletModelsProvider: { wallets },
            floatingSheetPresenter: presenter ?? FloatingSheetPresenterSpy()
        )
        return trackForMemoryLeaks(viewModel)
    }

    /// Waits one main-queue turn so the selector's wallet items arrive.
    func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    func open(_ sut: SUT) async -> CollectiblesCoordinator.Options? {
        var options: CollectiblesCoordinator.Options?
        sut.openCollectibles { options = $0 }
        await sut.openingTask?.value
        return options
    }
}

// MARK: - Stubs

private final class WalletStub: UserWalletModelMock {
    private let id: UserWalletId
    private let accountsManager: AccountModelsManager

    init(_ id: String) {
        self.id = UserWalletId(value: Data(id.utf8))
        accountsManager = AccountModelsManagerStub(
            account: CryptoAccountModelMock(
                isMainAccount: true,
                walletModelsManager: WalletModelsManagerTestsMock(),
                onArchive: { _ in }
            )
        )
    }

    override var userWalletId: UserWalletId { id }
    override var config: UserWalletConfig { UserWalletConfigStub() }
    override var accountModelsManager: AccountModelsManager { accountsManager }
}

private final class AccountStatusProviderStub: CollectiblesAccountStatusProvider {
    private(set) var loadCallCount = 0

    private let result: Result<CollectiblesAccountStatus, Error>

    init(result: Result<CollectiblesAccountStatus, Error>) {
        self.result = result
    }

    func load() async throws -> CollectiblesAccountStatus {
        loadCallCount += 1
        return try result.get()
    }
}

private final class FloatingSheetPresenterSpy: FloatingSheetPresenter {
    private(set) var enqueuedSheets: [any FloatingSheetContentViewModel] = []

    private var enqueueContinuation: CheckedContinuation<Void, Never>?

    func enqueue(sheet: some FloatingSheetContentViewModel) {
        enqueuedSheets.append(sheet)
        enqueueContinuation?.resume()
        enqueueContinuation = nil
    }

    func waitForSheets(count: Int, maxAttempts: Int = 50) async {
        for _ in 0 ..< maxAttempts where enqueuedSheets.count < count {
            await withCheckedContinuation { enqueueContinuation = $0 }
        }

        if enqueuedSheets.count < count {
            Issue.record("Expected \(count) sheet(s), enqueued \(enqueuedSheets.count)")
        }
    }

    func removeActiveSheet() {}
    func removeAllSheets() {}
    func pauseSheetsDisplaying() {}
    func resumeSheetsDisplaying() {}
}

private final class HangingAccountStatusProviderStub: CollectiblesAccountStatusProvider {
    func load() async throws -> CollectiblesAccountStatus {
        try await Task.sleep(for: .seconds(60))
        return .exists
    }
}

private enum StubError: Error {
    case requested
}
