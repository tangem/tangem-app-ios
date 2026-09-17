//
//  PendingExpressTxStatusBottomSheetViewModelRatingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemAssets
import TangemFoundation
import TangemSdk
import TangemTestKit
import TangemUI
import Testing
@testable import Tangem

@Suite("PendingExpressTxStatusBottomSheetViewModel Rating", .serialized)
@MainActor
final class PendingExpressTxStatusBottomSheetViewModelRatingTests: LeakTrackingTestSuite {
    typealias SUT = PendingExpressTxStatusBottomSheetViewModel

    @Test("CEX: ratingViewModel is created when externalTxId exists")
    func cexRatingViewModelCreated() async {
        await withInjectedDependencies {
            let (sut, _) = makeSUT(expressTransactionId: anyExpressTransactionId, externalTxId: anyExternalID)
            await awaitRatingViewModel(on: sut)
        }
    }

    @Test("DEX: ratingViewModel is created using expressTransactionId when externalTxId is nil")
    func dexRatingViewModelCreated() async {
        await withInjectedDependencies {
            let (sut, _) = makeSUT(expressTransactionId: anyExpressTransactionId, externalTxId: nil)
            await awaitRatingViewModel(on: sut)
        }
    }

    @Test("ratingViewModel created after transaction updates with externalTxId")
    func ratingViewModelUpdatedWithExternalTxId() async throws {
        try await withInjectedDependencies {
            let (sut, subject) = makeSUT(expressTransactionId: anyExpressTransactionId, externalTxId: nil)

            let firstInstance = try #require(sut.ratingViewModel)

            await sendUpdate(to: subject, externalTxId: anyExternalID)

            // Should keep the same instance (created only once)
            #expect(sut.ratingViewModel === firstInstance)
        }
    }

    @Test("ratingViewModel created only once")
    func ratingViewModelCreatedOnlyOnce() async throws {
        try await withInjectedDependencies {
            let (sut, subject) = makeSUT(externalTxId: anyExternalID)

            let firstInstance = try #require(sut.ratingViewModel)

            await sendUpdate(to: subject, externalTxId: anyExternalID)

            #expect(sut.ratingViewModel === firstInstance)
        }
    }

    @Test("No rating while the swap is still running", arguments: [
        PendingExpressTransactionStatus.created, .awaitingDeposit, .awaitingHash, .confirming, .buying, .exchanging, .sendingToUser,
        .verificationRequired, .paused, .unknown, .failed, .refunding,
    ])
    func noRatingWhileRunning(status: PendingExpressTransactionStatus) async {
        await withInjectedDependencies {
            let (sut, _) = makeSUT(externalTxId: anyExternalID, status: status)

            #expect(sut.ratingViewModel == nil)
        }
    }

    @Test("Rating appears once the swap reaches a final status", arguments: [
        PendingExpressTransactionStatus.finished, .refunded, .expired, .txFailed,
    ])
    func ratingAppearsOnFinalStatus(status: PendingExpressTransactionStatus) async {
        await withInjectedDependencies {
            let (sut, _) = makeSUT(externalTxId: anyExternalID, status: status)

            #expect(sut.ratingViewModel != nil)
        }
    }

    @Test("Rating appears when a running swap finishes while the sheet is open")
    func ratingAppearsWhenSwapFinishes() async throws {
        try await withInjectedDependencies {
            let (sut, subject) = makeSUT(externalTxId: anyExternalID, status: .exchanging)
            #expect(sut.ratingViewModel == nil)

            await sendUpdate(to: subject, externalTxId: anyExternalID, status: .finished)

            _ = try #require(sut.ratingViewModel)
        }
    }

    @Test("ratingViewModel is available immediately for DEX transactions")
    func ratingViewModelAvailableImmediatelyForDex() async throws {
        try await withInjectedDependencies {
            let (sut, _) = makeSUT(expressTransactionId: anyExpressTransactionId, externalTxId: nil)

            var receivedValues: [RatingViewModel?] = []
            let cancellable = sut.$ratingViewModel.sink { receivedValues.append($0) }

            // Should have ratingViewModel immediately (using expressTransactionId)
            #expect(receivedValues.count >= 1)
            let firstValue = try #require(receivedValues.first)
            _ = try #require(firstValue)

            cancellable.cancel()
            await drainMainQueue()
        }
    }
}

// MARK: - Helpers

private extension PendingExpressTxStatusBottomSheetViewModelRatingTests {
    var anyExternalID: String { "external_123" }
    var anyExpressTransactionId: String { "express_tx_1" }

    // MARK: - Dependency Isolation

    func withInjectedDependencies<T>(operation: () async throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousKeys = InjectedValues[\.keysManager]
            let previousProvider = InjectedValues[\.ratingProvider]
            let previousQuotes = InjectedValues[\.quotesRepository] as? (TokenQuotesRepository & TokenQuotesRepositoryUpdater)

            InjectedValues[\.keysManager] = KeysManagerStub()
            InjectedValues[\.ratingProvider] = RatingProviderSpy()
            InjectedValues.setTokenQuotesRepository(TokenQuotesRepositoryStub(quotes: stubQuotes))

            defer {
                InjectedValues[\.keysManager] = previousKeys
                InjectedValues[\.ratingProvider] = previousProvider
                if let previousQuotes {
                    InjectedValues.setTokenQuotesRepository(previousQuotes)
                }
            }
            return try await operation()
        }
    }

    /// Preloaded quote for the SUT's token so `BalanceConverter.convertToFiat` resolves synchronously
    /// and the view model's `init` does not spin up an unstructured rate-loading `Task` that would keep it
    /// alive past the suite's synchronous leak check.
    var stubQuotes: Quotes {
        guard let currencyId = makeTokenItem().currencyId else {
            return [:]
        }

        let quote = TokenQuote(
            currencyId: currencyId,
            price: 1,
            priceUsd: nil,
            priceChange24h: nil,
            priceChange7d: nil,
            priceChange30d: nil,
            currencyCode: "USD"
        )
        return [currencyId: quote]
    }

    // MARK: - Async Helpers

    func awaitRatingViewModel(on sut: SUT) async {
        var localCancellable: AnyCancellable?
        await confirmation { confirm in
            localCancellable = sut.$ratingViewModel
                .compactMap { $0 }
                .first()
                .sink { _ in confirm() }
        }
        localCancellable?.cancel()
        await drainMainQueue()
    }

    func sendUpdate(
        to subject: CurrentValueSubject<[PendingTransaction], Never>,
        externalTxId: String,
        status: PendingExpressTransactionStatus = .finished
    ) async {
        subject.send([makePendingTransaction(externalTxId: externalTxId, status: status)])
        await drainMainQueue()
    }

    /// Waits one main-queue turn so a pending `receive(on: DispatchQueue.main)` delivery drains
    /// before the suite's synchronous leak check, releasing transiently-retained instances.
    func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    func makeSUT(
        expressTransactionId: String = "express_tx_1",
        externalTxId: String? = nil,
        status: PendingExpressTransactionStatus = .finished
    ) -> (sut: SUT, subject: CurrentValueSubject<[PendingTransaction], Never>) {
        let tx = makePendingTransaction(expressTransactionId: expressTransactionId, externalTxId: externalTxId, status: status)
        let subject = CurrentValueSubject<[PendingTransaction], Never>([tx])
        let manager = PendingExpressTransactionsManagerStub(subject: subject)

        let sut = SUT(
            pendingTransaction: tx,
            currentTokenItem: makeTokenItem(),
            userWalletInfo: makeUserWalletInfo(),
            pendingTransactionsManager: manager,
            router: PendingExpressTxStatusRouterStub()
        )

        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(subject)
        trackForMemoryLeaks(manager)

        return (sut, subject)
    }

    func makePendingTransaction(
        expressTransactionId: String = "express_tx_1",
        externalTxId: String? = nil,
        status: PendingExpressTransactionStatus = .finished
    ) -> PendingTransaction {
        let tokenItem = makeTokenItem()
        let tokenTxInfo = ExpressPendingTransactionRecord.TokenTxInfo(
            userWalletId: "test_wallet_id",
            tokenItem: tokenItem,
            address: "0x123",
            amountString: "100",
            isCustom: false
        )

        let provider = ExpressPendingTransactionRecord.Provider(
            id: "test_provider",
            name: "Test Provider",
            iconURL: nil,
            type: .cex
        )

        return PendingTransaction(
            type: .swap(source: tokenTxInfo, destination: tokenTxInfo),
            expressTransactionId: expressTransactionId,
            externalTxId: externalTxId,
            externalTxURL: externalTxId.map { "https://example.com/tx/\($0)" },
            provider: provider,
            date: Date(),
            transactionStatus: status,
            refundedTokenItem: nil,
            statuses: [status],
            averageDuration: nil,
            createdAt: nil
        )
    }

    func makeTokenItem() -> TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }
}

// MARK: - Stubs

private final class PendingExpressTransactionsManagerStub: PendingExpressTransactionsManager {
    private let subject: CurrentValueSubject<[PendingTransaction], Never>

    var pendingTransactions: [PendingTransaction] { subject.value }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> { subject.eraseToAnyPublisher() }

    init(subject: CurrentValueSubject<[PendingTransaction], Never>) {
        self.subject = subject
    }

    func hideTransaction(with id: String) {}
}

private final class PendingExpressTxStatusRouterStub: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {}
    func openRefundCurrency(walletModel: any WalletModel, userWalletModel: UserWalletModel) {}
    func dismissPendingTxSheet() {}
}

private final class TokenQuotesRepositoryStub: TokenQuotesRepository, TokenQuotesRepositoryUpdater {
    typealias QuotesPublisher = AnyPublisher<Quotes, Never>

    let quotes: Quotes

    init(quotes: Quotes) {
        self.quotes = quotes
    }

    var quotesPublisher: QuotesPublisher {
        Just(quotes).eraseToAnyPublisher()
    }

    func quote(for currencyId: String) async throws -> TokenQuote {
        guard let quote = quotes[currencyId] else {
            throw ErrorStub.quoteNotFound
        }
        return quote
    }

    func loadQuotes(currencyIds: [String]) -> QuotesPublisher {
        Just(quotes).eraseToAnyPublisher()
    }

    func fetchFreshQuoteFor(currencyId: String, shouldUpdateCache: Bool) async throws -> TokenQuote {
        try await quote(for: currencyId)
    }

    func saveQuotes(_ quotes: [TokenQuote]) {}

    enum ErrorStub: Error {
        case quoteNotFound
    }
}
