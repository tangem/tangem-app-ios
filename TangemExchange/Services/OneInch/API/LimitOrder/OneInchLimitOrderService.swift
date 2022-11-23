//
//  OneInchLimitOrderService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class OneInchLimitOrderService: OneInchLimitOrderProvider {
    let isDebug: Bool
    private lazy var networkService: NetworkService = NetworkService(isDebug: isDebug)

    init(isDebug: Bool) {
        self.isDebug = isDebug
    }

    func ordersForAddress(blockchain: ExchangeBlockchain, parameters: OrdersForAddressParameters) async -> Result<[LimitOrder], ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: LimitOrderTarget.ordersForAddress(blockchain: blockchain, parameters: parameters)))
    }

    func allOrders(blockchain: ExchangeBlockchain, parameters: AllOrdersParameters) async -> Result<[LimitOrder], ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: LimitOrderTarget.allOrders(blockchain: blockchain, parameters: parameters)))
    }

    func countOrders(blockchain: ExchangeBlockchain, statuses: [ExchangeOrderStatus]) async -> Result<CountLimitOrders, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: LimitOrderTarget.countOrders(blockchain: blockchain, statuses: statuses)))
    }

    func events(blockchain: ExchangeBlockchain, limit: Int) async -> Result<[EventsLimitOrder], ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: LimitOrderTarget.events(blockchain: blockchain, limit: limit)))
    }

    func hasActiveOrdersWithPermit(blockchain: ExchangeBlockchain,
                                   walletAddress: String,
                                   tokenAddress: String) async -> Result<Bool, ExchangeInchError> {
        let target = LimitOrderTarget.hasActiveOrdersWithPermit(blockchain: blockchain,
                                                                walletAddress: walletAddress,
                                                                tokenAddress: tokenAddress)

        let response: Result<ActiveOrdersWithPermitDTO, ExchangeInchError> = await networkService.request(with: BaseTarget(target: target))
        switch response {
        case .success(let dto):
            return .success(dto.result)
        case .failure(let error):
            return .failure(error)
        }
    }
}
