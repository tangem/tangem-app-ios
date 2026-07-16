//
//  SwapModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import Testing
import TangemTestKit
@testable import TangemExpress
@testable import Tangem

@Suite("SwapModel")
final class SwapModelTests: LeakTrackingTestSuite {
    @Test("SwapModel deallocates properly without memory leaks")
    func swapModelDeallocatesProperly() async {
        let sut = makeSUT()
        trackForMemoryLeaks(sut)

        _ = sut.sourceToken
        _ = sut.receiveToken
        _ = sut.statePublisher
    }
}

// MARK: - Helpers

private extension SwapModelTests {
    func makeSUT() -> SwapModel {
        SwapModel(
            sourceToken: nil,
            receiveToken: nil,
            expressManager: ExpressManagerStub(),
            swapRepository: SwapRepositoryStub(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            pairUpdateHandler: SwapPairUpdateHandlerStub(),
            balanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureCheckerStub(),
            shouldStartInitialLoading: false
        )
    }
}

// MARK: - Stubs

private actor ExpressManagerStub: ExpressManager {
    func getCurrentPair() -> ExpressManagerSwappingPair? { nil }
    func getAmountType() -> ExpressAmountType? { nil }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        .idle
    }

    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState {
        .idle
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState {
        .idle
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState {
        .idle
    }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState {
        .idle
    }

    func requestData() async throws -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "",
            extraDestinationId: nil,
            txValue: .zero,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }
}

private final class SwapRepositoryStub: SwapRepository {
    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency], userWalletInfo: UserWalletInfo) async throws {}
    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {}
    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] { [] }
    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }
    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }
    func providers(userWalletInfo: UserWalletInfo) async throws -> [ExpressProvider] { [] }

    // ExpressRepository
    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}
    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] { [] }
}

private final class ExpressPendingTransactionRepositoryStub: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] { [] }
    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { .just(output: []) }
    func updateItems(_ items: [ExpressPendingTransactionRecord]) {}
    func swapTransactionDidSend(_ transaction: SentSwapTransactionData) {}
    func hideSwapTransaction(with id: String) {}
}

private final class SwapPairUpdateHandlerStub: SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        .idle
    }
}

private final class SwapBalanceRestrictionFeatureCheckerStub: SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction { .none }
}
