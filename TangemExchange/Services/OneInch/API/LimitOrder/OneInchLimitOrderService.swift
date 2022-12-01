//
//  OneInchLimitOrderService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct OneInchLimitOrderService: OneInchLimitOrderServicing {
    private let provider = MoyaProvider<OneInchBaseTarget>()

    func ordersForAddress(blockchain: ExchangeBlockchain, parameters: OrdersForAddressParameters) async -> Result<[LimitOrder], ExchangeInchError> {
        await request(
            target: OneInchBaseTarget(target: LimitOrderTarget.ordersForAddress(parameters), blockchain: blockchain)
        )
    }

    func allOrders(blockchain: ExchangeBlockchain, parameters: AllOrdersParameters) async -> Result<[LimitOrder], ExchangeInchError> {
        await request(
            target: OneInchBaseTarget(target: LimitOrderTarget.allOrders(parameters), blockchain: blockchain)
        )
    }

    func countOrders(blockchain: ExchangeBlockchain, statuses: [ExchangeOrderStatus]) async -> Result<CountLimitOrders, ExchangeInchError> {
        await request(
            target: OneInchBaseTarget(target: LimitOrderTarget.countOrders(statuses), blockchain: blockchain)
        )
    }

    func events(blockchain: ExchangeBlockchain, limit: Int) async -> Result<[EventsLimitOrder], ExchangeInchError> {
        await request(
            target: OneInchBaseTarget(target: LimitOrderTarget.events(limit), blockchain: blockchain)
        )
    }

    func hasActiveOrdersWithPermit(blockchain: ExchangeBlockchain,
                                   walletAddress: String,
                                   tokenAddress: String) async -> Result<Bool, ExchangeInchError> {
        let target = LimitOrderTarget.hasActiveOrdersWithPermit(walletAddress: walletAddress,
                                                                tokenAddress: tokenAddress)

        let response: Result<ActiveOrdersWithPermitDTO, ExchangeInchError> = await request(
            target: OneInchBaseTarget(target: target, blockchain: blockchain)
        )

        switch response {
        case .success(let dto):
            return .success(dto.result)
        case .failure(let error):
            return .failure(error)
        }
    }
}

private extension OneInchLimitOrderService {
    func request<T: Decodable>(target: OneInchBaseTarget) async -> Result<T, ExchangeInchError> {
        var response: Response

        do {
            response = try await provider.asyncRequest(target)
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            return .failure(.serverError(withError: error))
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return .success(try decoder.decode(T.self, from: response.data))
        } catch {
            return .failure(.decodeError(error: error))
        }
    }
}

