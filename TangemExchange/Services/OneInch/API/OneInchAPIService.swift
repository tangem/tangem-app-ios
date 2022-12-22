//
//  OneInchAPIService.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct OneInchAPIService: OneInchAPIServicing {
    private let provider = MoyaProvider<OneInchBaseTarget>()
    init() {}

    func healthCheck(blockchain: ExchangeBlockchain) async -> Result<HealthCheck, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: HealthCheckTarget.healthCheck, blockchain: blockchain)
        )
    }

    func tokens(blockchain: ExchangeBlockchain) async -> Result<TokensList, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: InfoTarget.tokens, blockchain: blockchain)
        )
    }

    func presets(blockchain: ExchangeBlockchain) async -> Result<PresetsConfiguration, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: InfoTarget.presets, blockchain: blockchain)
        )
    }

    func liquiditySources(blockchain: ExchangeBlockchain) async -> Result<LiquiditySourcesList, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: InfoTarget.liquiditySources, blockchain: blockchain)
        )
    }

    func quote(blockchain: ExchangeBlockchain, parameters: QuoteParameters) async -> Result<QuoteData, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: ExchangeTarget.quote(parameters), blockchain: blockchain)
        )
    }

    func swap(blockchain: ExchangeBlockchain, parameters: ExchangeParameters) async -> Result<ExchangeData, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: ExchangeTarget.swap(parameters), blockchain: blockchain)
        )
    }

    func spender(blockchain: ExchangeBlockchain) async -> Result<ApproveSpender, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: ApproveTarget.spender, blockchain: blockchain)
        )
    }

    func approveTransaction(blockchain: ExchangeBlockchain, approveTransactionParameters: ApproveTransactionParameters) async -> Result<ApprovedTransactionData, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: ApproveTarget.transaction(approveTransactionParameters), blockchain: blockchain)
        )
    }

    func allowance(blockchain: ExchangeBlockchain, allowanceParameters: ApproveAllowanceParameters) async -> Result<ApprovedAllowance, ExchangeProviderError> {
        await request(
            target: OneInchBaseTarget(target: ApproveTarget.allowance(allowanceParameters), blockchain: blockchain)
        )
    }
}

private extension OneInchAPIService {
    func request<T: Decodable>(target: OneInchBaseTarget) async -> Result<T, ExchangeProviderError> {
        var response: Response

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            response = try await provider.asyncRequest(target)
        } catch {
            logError(target: target, error: error)
            return .failure(.requestError(error))
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            do {
                let inchError = try decoder.decode(OneInchError.self, from: response.data)
                logError(target: target, response: response, error: inchError)
                return .failure(.oneInchError(inchError))
            } catch {
                logError(target: target, response: response, error: error)
                return .failure(.decodingError(error))
            }
        }

        do {
            return .success(try decoder.decode(T.self, from: response.data))
        } catch {
            logError(target: target, response: response, error: error)
            return .failure(.decodingError(error))
        }
    }

    func logError(target: OneInchBaseTarget, response: Response? = nil, error: Any) {
        var info: String = ""
        if let response {
            info = String(data: response.data, encoding: .utf8)!
        }

        print(
            "Error when request to target \(target.path)",
            "with info \(info)",
            "\(error)"
        )
    }
}
