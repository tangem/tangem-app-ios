//
//  ExchangeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol ExchangeManagerDelegate {
    func exchangeManagerDidRequestUpdate(_ availabilityState: SwappingAvailabilityState)
}

public enum SwappingAvailabilityState {
    case loading
    case available
    case requiredPermission
    case requiredRefreshRates
}

public protocol ExchangeManager {
    /// Available network for selected as target to swap
    func getNetworksAvailableToSwap() -> [String]
    
    /// Items which currently to swapping
    func getExchangeItems() -> ExchangeItems
    
    /// Update swapping items and reload rates
    func update(exchangeItems: ExchangeItems)
    
    /// Approve swapping items
    func approveSwapItems()
    
    /// User request swap items
    func swapItems()
}

class DefaultExchangeManager {
    // MARK: - Dependencies
    private let provider: ExchangeProvider
    private let blockchainProvider: BlockchainNetworkProvider

    // MARK: - Internal
    private lazy var refreshTxDataTimerPublisher = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private var exchangeItems: ExchangeItems

    private var bag: Set<AnyCancellable> = []

    init(
        provider: ExchangeProvider,
        blockchainProvider: BlockchainNetworkProvider,
        exchangeItems: ExchangeItems
    ) {
        self.provider = provider
        self.blockchainProvider = blockchainProvider
        self.exchangeItems = exchangeItems
    }
}

// MARK: - Private

private extension CommonExchangeManager {
    
}
