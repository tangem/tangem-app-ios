//
//  SwapStubs.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
@testable import TangemExpress
@testable import Tangem

/// Keeps every `ProvidersState` a `SwapModel` published, in order — the terminal value alone can't tell a
/// state that settled from one that was replaced mid-flight.
final class SwapProvidersStateRecorder {
    private let states = OSAllocatedUnfairLock(initialState: [SwapModel.ProvidersState]())
    private var bag: AnyCancellable?

    init(_ model: SwapModel) {
        bag = model.statePublisher.sink { [states] state in
            states.withLock { $0.append(state) }
        }
    }

    var count: Int { states.withLock { $0.count } }
    var latest: SwapModel.ProvidersState? { states.withLock { $0.last } }
    var all: [SwapModel.ProvidersState] { states.withLock { $0 } }
}

final class SwapRepositoryStub: SwapRepository {
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

final class ExpressPendingTransactionRepositoryStub: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] { [] }
    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { .just(output: []) }
    func updateItems(_ items: [ExpressPendingTransactionRecord]) {}
    func swapTransactionDidSend(_ transaction: SentSwapTransactionData) {}
    func hideSwapTransaction(with id: String) {}
}
