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
    case requiredRefresh(occuredError: Error)
}

public protocol ExchangeManager {
    /// Available network for selected as target to swap
    func getNetworksAvailableToSwap() -> [String]
    
    /// Items which currently to swapping
    func getExchangeItems() -> ExchangeItems
    
    /// Update swapping items and reload rates
    func update(exchangeItems: ExchangeItems)
    
    func isAvailableForExchange(amount: Decimal)
    
    /// Approve swapping items
    func approveSwapItems()
    
    /// User request swap items
    func swapItems()
}

class DefaultExchangeManager {
    // MARK: - Dependencies

    private let exchangeProvider: ExchangeProvider
    private let blockchainProvider: BlockchainNetworkProvider
    private weak var delegate: ExchangeManagerDelegate?

    // MARK: - Internal

    private lazy var refreshTxDataTimerPublisher = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var availabilityState: SwappingAvailabilityState = .available
    private var exchangeItems: ExchangeItems
    private var tokenExchangeAllowanceLimit: Decimal?
    private var swappingData: ExchangeSwapDataModel?
    private var bag: Set<AnyCancellable> = []

    init(
        exchangeProvider: ExchangeProvider,
        blockchainProvider: BlockchainNetworkProvider,
        exchangeItems: ExchangeItems
    ) {
        self.exchangeProvider = exchangeProvider
        self.blockchainProvider = blockchainProvider
        self.exchangeItems = exchangeItems
    }
}

// MARK: - Private

public extension DefaultExchangeManager: ExchangeManager {
    func isAvailableForExchange(amount: Decimal) -> Bool {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request available for exchange for coin")
            return true
        }
        
        guard let tokenExchangeAllowanceLimit else {
            assertionFailure("TokenExchangeAllowanceLimit hasn't been updated")
            return false
        }

        return amount <= tokenExchangeAllowanceLimit
    }
}

private extension DefaultExchangeManager {
    func updateExchangeAmountAllowance() {
        guard exchangeItems.source.isToken else {
            print("Unnecessary request fetchExchangeAmountAllowance for coin")
            return
        }

        Task {
            do {
                tokenExchangeAllowanceLimit = try await exchangeProvider.fetchExchangeAmountAllowance(for: exchangeItems.source)
            } catch {
                tokenExchangeAllowanceLimit = nil
                availabilityState = .requiredRefresh(occuredError: error)
            }
        }
    }
    
    func updateSwappingInformation(amount: Decimal) {
        Task {
            do {
                swappingData = try await exchangeProvider.fetchTxDataForSwap(
                    items: exchangeItems,
                    amount: amount.description,
                    slippage: 1 // Default value
                )
            } catch {
                swappingData = nil
                availabilityState = .requiredRefresh(occuredError: error)
            }
        }
    }
}
