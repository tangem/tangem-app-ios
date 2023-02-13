//
//  OneInchLimitOrderServicing.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OneInchLimitOrderServicing {
    func ordersForAddress(blockchain: ExchangeBlockchain, parameters: OrdersForAddressParameters) async -> Result<[LimitOrder], ExchangeProviderError>
    func allOrders(blockchain: ExchangeBlockchain, parameters: AllOrdersParameters) async -> Result<[LimitOrder], ExchangeProviderError>
    func countOrders(blockchain: ExchangeBlockchain, statuses: [ExchangeOrderStatus]) async -> Result<CountLimitOrders, ExchangeProviderError>
    func events(blockchain: ExchangeBlockchain, limit: Int) async -> Result<[EventsLimitOrder], ExchangeProviderError>
    func hasActiveOrdersWithPermit(blockchain: ExchangeBlockchain, walletAddress: String, tokenAddress: String) async -> Result<Bool, ExchangeProviderError>
}
