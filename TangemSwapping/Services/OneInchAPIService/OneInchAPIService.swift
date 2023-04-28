//
//  OneInchAPIService.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct OneInchAPIService: OneInchAPIServicing {
    private let provider: MoyaProvider<OneInchBaseTarget>
    private let logger: SwappingLogger

    init(logger: SwappingLogger, configuration: URLSessionConfiguration = .oneInchURLConfiguration) {
        self.logger = logger
        let session = Session(configuration: configuration)
        provider = MoyaProvider<OneInchBaseTarget>(session: session)
    }

    func healthCheck(blockchain: SwappingBlockchain) async -> Result<HealthCheck, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: HealthCheckTarget.healthCheck, blockchain: blockchain)
        )
    }

    func tokens(blockchain: SwappingBlockchain) async -> Result<TokensList, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: InfoTarget.tokens, blockchain: blockchain)
        )
    }

    func presets(blockchain: SwappingBlockchain) async -> Result<PresetsConfiguration, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: InfoTarget.presets, blockchain: blockchain)
        )
    }

    func liquiditySources(blockchain: SwappingBlockchain) async -> Result<LiquiditySourcesList, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: InfoTarget.liquiditySources, blockchain: blockchain)
        )
    }

    func quote(blockchain: SwappingBlockchain, parameters: QuoteParameters) async -> Result<QuoteData, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: SwappingTarget.quote(parameters), blockchain: blockchain)
        )
    }

    func swap(blockchain: SwappingBlockchain, parameters: SwappingParameters) async -> Result<SwappingData, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: SwappingTarget.swap(parameters), blockchain: blockchain)
        )
    }

    func spender(blockchain: SwappingBlockchain) async -> Result<ApproveSpender, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: ApproveTarget.spender, blockchain: blockchain)
        )
    }

    func approveTransaction(blockchain: SwappingBlockchain, approveTransactionParameters: ApproveTransactionParameters) async -> Result<ApprovedTransactionData, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: ApproveTarget.transaction(approveTransactionParameters), blockchain: blockchain)
        )
    }

    func allowance(blockchain: SwappingBlockchain, allowanceParameters: ApproveAllowanceParameters) async -> Result<ApprovedAllowance, SwappingProviderError> {
        await request(
            target: OneInchBaseTarget(target: ApproveTarget.allowance(allowanceParameters), blockchain: blockchain)
        )
    }
}

private extension OneInchAPIService {
    func request<T: Decodable>(target: OneInchBaseTarget) async -> Result<T, SwappingProviderError> {
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
        var info = ""
        if let response {
            info = String(data: response.data, encoding: .utf8)!
        }

        logger.debug(
            """
            Error when request to target \(target.path)
            with info \(info)
            \(error)
            """
        )
    }
}

extension URLSessionConfiguration {
    static var oneInchURLConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return configuration
    }
}
