//
//  SwapManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

typealias SwapManagerState = ExpressInteractor.State
typealias SwapManagerSwappingPair = ExpressInteractor.SwappingPair

protocol SwapManager: SendApproveDataBuilderInput {
    var isSwapAvailable: Bool { get }

    var swappingPair: SwapManagerSwappingPair { get }
    var swappingPairPublisher: AnyPublisher<SwapManagerSwappingPair, Never> { get }

    var state: SwapManagerState { get }
    var statePublisher: AnyPublisher<SwapManagerState, Never> { get }

    var providers: [ExpressAvailableProvider] { get async }
    var selectedProvider: ExpressAvailableProvider? { get async }

    var providersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> { get }
    var selectedProviderPublisher: AnyPublisher<ExpressAvailableProvider?, Never> { get }

    func update(amount: Decimal?)
    func update(destination: TokenItem?, address: String?, accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?)
    func update(provider: ExpressAvailableProvider)
    func update(feeOption: FeeOption)

    func update()
    func updateFees()
    func send() async throws -> TransactionDispatcherResult
}
