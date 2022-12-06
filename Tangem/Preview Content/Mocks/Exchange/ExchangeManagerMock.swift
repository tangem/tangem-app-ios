//
//  ExchangeManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

struct ExchangeManagerMock: ExchangeManager {
    func setDelegate(_ delegate: TangemExchange.ExchangeManagerDelegate) {}
    
    func getNetworksAvailableToExchange() -> [String] { [] }
    
    func getExchangeItems() -> TangemExchange.ExchangeItems {
        ExchangeItems(source: .mock, destination: .mock)
    }
    
    func getAvailabilityState() -> TangemExchange.ExchangeAvailabilityState {
        .idle
    }
    
    func update(exchangeItems: TangemExchange.ExchangeItems) {
        
    }
    
    func update(amount: Decimal?) {
        
    }
    
    func isAvailableForExchange() -> Bool {
        true
    }
    
    func refresh() {
        
    }
}
