//
//  SwapManagerInterfaces.swift
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

protocol SwapManager {
    var swappingPair: SwapManagerSwappingPair { get }
    var state: SwapManagerState { get }

    var swappingPairPublisher: AnyPublisher<SwapManagerSwappingPair, Never> { get }
    var statePublisher: AnyPublisher<SwapManagerState, Never> { get }

    func update(amount: Decimal?)
    func update(destination: TokenItem?, address: String?)

    func update(provider: ExpressAvailableProvider)
}
