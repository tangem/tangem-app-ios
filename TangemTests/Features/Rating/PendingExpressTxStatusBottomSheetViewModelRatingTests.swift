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

    @Test("ratingViewModel is available immediately for DEX transactions")
    func ratingViewModelAvailableImmediatelyForDex() throws {
        try withInjectedDependenciesSync {
            let (sut, _) = makeSUT(expressTransactionId: anyExpressTransactionId, externalTxId: nil)

            var receivedValues: [RatingViewModel?] = []
            let cancellable = sut.$ratingViewModel.sink { receivedValues.append($0) }

            // Should have ratingViewModel immediately (using expressTransactionId)
            #expect(receivedValues.count >= 1)
            let firstValue = try #require(receivedValues.first)
            _ = try #require(firstValue)

            cancellable.cancel()
        }
    }
}

// MARK: - Helpers

private extension PendingExpressTxStatusBottomSheetViewModelRatingTests {
    var anyExternalID: String { "external_123" }
    var anyExpressTransactionId: String { "express_tx_1" }

    // MARK: - Dependency Isolation

    func withInjectedDependencies<T>(operation: () async throws -> T) async rethrows -> T {
        let previousKeys = InjectedValues[\.keysManager]
        let previousProvider = InjectedValues[\.ratingProvider]

        InjectedValues[\.keysManager] = KeysManagerStub()
        InjectedValues[\.ratingProvider] = RatingProviderSpy()

        defer {
            InjectedValues[\.keysManager] = previousKeys
            InjectedValues[\.ratingProvider] = previousProvider
        }
        return try await operation()
    }

    func withInjectedDependenciesSync<T>(operation: () throws -> T) rethrows -> T {
        let previousKeys = InjectedValues[\.keysManager]
        let previousProvider = InjectedValues[\.ratingProvider]

        InjectedValues[\.keysManager] = KeysManagerStub()
        InjectedValues[\.ratingProvider] = RatingProviderSpy()

        defer {
            InjectedValues[\.keysManager] = previousKeys
            InjectedValues[\.ratingProvider] = previousProvider
        }
        return try operation()
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
    }

    func sendUpdate(
        to subject: CurrentValueSubject<[PendingTransaction], Never>,
        externalTxId: String
    ) async {
        subject.send([makePendingTransaction(externalTxId: externalTxId)])
        // Allow Combine pipeline to process the update on main queue
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    func makeSUT(
        expressTransactionId: String = "express_tx_1",
        externalTxId: String? = nil
    ) -> (sut: SUT, subject: CurrentValueSubject<[PendingTransaction], Never>) {
        let tx = makePendingTransaction(expressTransactionId: expressTransactionId, externalTxId: externalTxId)
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
        externalTxId: String? = nil
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
            transactionStatus: .awaitingDeposit,
            refundedTokenItem: nil,
            statuses: [.awaitingDeposit],
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
            refcode: nil,
            signer: TangemSignerStub(),
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
