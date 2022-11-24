//
//  OneInchLimitOrderService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct OneInchLimitOrderService: OneInchLimitOrderProvider {
    private var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let provider = MoyaProvider<BaseTarget>()

    func ordersForAddress(blockchain: ExchangeBlockchain, parameters: OrdersForAddressParameters) async -> Result<[LimitOrder], ExchangeInchError> {
        await request(target: BaseTarget(target: LimitOrderTarget.ordersForAddress(blockchain: blockchain, parameters: parameters)))
    }

    func allOrders(blockchain: ExchangeBlockchain, parameters: AllOrdersParameters) async -> Result<[LimitOrder], ExchangeInchError> {
        await request(target: BaseTarget(target: LimitOrderTarget.allOrders(blockchain: blockchain, parameters: parameters)))
    }

    func countOrders(blockchain: ExchangeBlockchain, statuses: [ExchangeOrderStatus]) async -> Result<CountLimitOrders, ExchangeInchError> {
        await request(target: BaseTarget(target: LimitOrderTarget.countOrders(blockchain: blockchain, statuses: statuses)))
    }

    func events(blockchain: ExchangeBlockchain, limit: Int) async -> Result<[EventsLimitOrder], ExchangeInchError> {
        await request(target: BaseTarget(target: LimitOrderTarget.events(blockchain: blockchain, limit: limit)))
    }

    func hasActiveOrdersWithPermit(blockchain: ExchangeBlockchain,
                                   walletAddress: String,
                                   tokenAddress: String) async -> Result<Bool, ExchangeInchError> {
        let target = LimitOrderTarget.hasActiveOrdersWithPermit(blockchain: blockchain,
                                                                walletAddress: walletAddress,
                                                                tokenAddress: tokenAddress)

        let response: Result<ActiveOrdersWithPermitDTO, ExchangeInchError> = await request(target: BaseTarget(target: target))
        switch response {
        case .success(let dto):
            return .success(dto.result)
        case .failure(let error):
            return .failure(error)
        }
    }
}

private extension OneInchLimitOrderService {
    func request<T: Decodable>(target: BaseTarget) async -> Result<T, ExchangeInchError> {
        var response: Response

        do {
            response = try await provider.asyncRequest(target)
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            return .failure(.serverError(withError: error))
        }

        do {
            return .success(try jsonDecoder.decode(T.self, from: response.data))
        } catch {
            return .failure(.decodeError(error: error))
        }
    }
}

