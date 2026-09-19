//
//  PendingExpressTxStatusBottomSheetViewModelOnrampAmountTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemSdk
import TangemTestKit
import TangemUI
import Testing
@testable import Tangem

/// Onramp records are created before the provider knows how much crypto the user gets; the status sheet must
/// pick the amount up from later `pendingTransactionsPublisher` updates instead of freezing the `init` value.
@Suite("PendingExpressTxStatusBottomSheetViewModel onramp destination amount", .serialized)
@MainActor
final class PendingExpressTxStatusBottomSheetViewModelOnrampAmountTests: LeakTrackingTestSuite {
    typealias SUT = PendingExpressTxStatusBottomSheetViewModel

    @Test("Shows the bare ticker while the bought amount is unknown")
    func showsTickerWhileAmountUnknown() async {
        await withInjectedDependencies {
            let (sut, _) = makeSUT(destinationAmountString: "0")

            #expect(sut.destinationAmountText == tokenItem.currencySymbol)
            #expect(sut.destinationFiatAmountTextState == .noData)
        }
    }

    @Test("Refreshes the amount and its fiat value once the status update carries it")
    func refreshesAmountFromStatusUpdate() async {
        await withInjectedDependencies {
            let (sut, subject) = makeSUT(destinationAmountString: "0")

            subject.send([makePendingTransaction(destinationAmountString: "100")])
            await drainMainQueue()

            let formatter = BalanceFormatter()
            #expect(sut.destinationAmountText == formatter.formatCryptoBalance(100, currencyCode: tokenItem.currencySymbol))
            #expect(sut.destinationFiatAmountTextState == .loaded(text: formatter.formatFiatBalance(100)))
        }
    }

    @Test("Keeps the amount when a status update does not change it")
    func keepsAmountWhenUnchanged() async {
        await withInjectedDependencies {
            let (sut, subject) = makeSUT(destinationAmountString: "100")
            let initialText = sut.destinationAmountText
            let initialFiatState = sut.destinationFiatAmountTextState

            subject.send([makePendingTransaction(destinationAmountString: "100", status: .buying)])
            await drainMainQueue()

            #expect(sut.destinationAmountText == initialText)
            #expect(sut.destinationFiatAmountTextState == initialFiatState)
        }
    }
}

// MARK: - Helpers

private extension PendingExpressTxStatusBottomSheetViewModelOnrampAmountTests {
    var tokenItem: TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

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

    /// Preloaded quote so `BalanceConverter.convertToFiat` resolves synchronously (no unstructured rate-loading task).
    var stubQuotes: Quotes {
        guard let currencyId = tokenItem.currencyId else {
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

    func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    func makeSUT(
        destinationAmountString: String
    ) -> (sut: SUT, subject: CurrentValueSubject<[PendingTransaction], Never>) {
        let tx = makePendingTransaction(destinationAmountString: destinationAmountString)
        let subject = CurrentValueSubject<[PendingTransaction], Never>([tx])
        let manager = PendingExpressTransactionsManagerStub(subject: subject)

        let sut = SUT(
            pendingTransaction: tx,
            currentTokenItem: tokenItem,
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
        destinationAmountString: String,
        status: PendingExpressTransactionStatus = .awaitingDeposit
    ) -> PendingTransaction {
        let destination = ExpressPendingTransactionRecord.TokenTxInfo(
            userWalletId: "test_wallet_id",
            tokenItem: tokenItem,
            address: "0x123",
            amountString: destinationAmountString,
            isCustom: false
        )

        let provider = ExpressPendingTransactionRecord.Provider(
            id: "test_provider",
            name: "Test Provider",
            iconURL: nil,
            type: .onramp
        )

        return PendingTransaction(
            type: .onramp(sourceAmount: 100, sourceCurrencySymbol: "USD", destination: destination),
            expressTransactionId: "express_tx_1",
            externalTxId: nil,
            externalTxURL: nil,
            provider: provider,
            date: Date(),
            transactionStatus: status,
            refundedTokenItem: nil,
            statuses: [status],
            averageDuration: nil,
            createdAt: nil
        )
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
