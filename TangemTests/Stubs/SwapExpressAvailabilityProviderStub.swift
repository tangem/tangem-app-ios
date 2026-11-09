//
//  SwapExpressAvailabilityProviderStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
@testable import Tangem

final class SwapExpressAvailabilityProviderStub: ExpressAvailabilityProvider {
    private let tokenSwapState: TokenItemExpressState
    private let tokenSwapStates: [TokenItem: TokenItemExpressState]
    private let updateState: ExpressAvailabilityUpdateState

    init(
        swapState: TokenItemExpressState = .available,
        swapStates: [TokenItem: TokenItemExpressState] = [:],
        updateState: ExpressAvailabilityUpdateState = .updated
    ) {
        tokenSwapState = swapState
        tokenSwapStates = swapStates
        self.updateState = updateState
    }

    var hasCache: Bool { true }
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var expressAvailabilityUpdateStateValue: ExpressAvailabilityUpdateState { updateState }
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> { .just(output: updateState) }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState { tokenSwapStates[tokenItem] ?? tokenSwapState }
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState { .unavailable }
    func canSwap(tokenItem: TokenItem) -> Bool { swapState(for: tokenItem) == .available }
    func canOnramp(tokenItem: TokenItem) -> Bool { false }
    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {}
}
