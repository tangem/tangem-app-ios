//
//  CosmosRestProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import TangemNetworkUtils

class CosmosRestProvider: HostProvider {
    var host: String {
        nodeInfo.host
    }

    private let nodeInfo: NodeInfo
    private let provider: TangemProvider<CosmosTarget>

    init(nodeInfo: NodeInfo, configuration: TangemProviderConfiguration) {
        self.nodeInfo = nodeInfo
        provider = TangemProvider<CosmosTarget>(configuration: configuration)
    }

    func accounts(address: String) -> AnyPublisher<CosmosAccountResponse?, Error> {
        requestPublisher(for: .accounts(address: address))
            .tryCatch { error -> AnyPublisher<CosmosAccountResponse?, Error> in
                if let cosmosError = error as? CosmosError,
                   cosmosError.code == 5 {
                    return .justWithError(output: nil)
                } else {
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }

    func querySmartContract<D: Decodable>(contractAddress: String, query: Data) -> AnyPublisher<CosmosCW20QueryResult<D>, Error> {
        requestPublisher(for: .querySmartContract(contractAddress: contractAddress, query: query))
    }

    func balances(address: String) -> AnyPublisher<CosmosBalanceResponse, Error> {
        requestPublisher(for: .balances(address: address))
    }

    func simulate(data: Data) -> AnyPublisher<CosmosSimulateResponse, Error> {
        requestPublisher(for: .simulate(data: data))
    }

    func txs(data: Data) -> AnyPublisher<CosmosTxResponse, Error> {
        requestPublisher(for: .txs(data: data))
    }

    func transactionStatus(hash: String) -> AnyPublisher<CosmosTxResponse, Error> {
        requestPublisher(for: .transactionStatus(hash: hash))
    }

    private func requestPublisher<T: Decodable>(for target: CosmosTarget.CosmosTargetType) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(CosmosTarget(baseURL: nodeInfo.url, type: target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .mapError { moyaError in
                if case .statusCode(let response) = moyaError,
                   let cosmosError = try? JSONDecoder().decode(CosmosError.self, from: response.data) {
                    return cosmosError
                }

                if case .objectMapping = moyaError {
                    return BlockchainSdkError.failedToParseNetworkResponse()
                }
                return moyaError
            }
            .eraseToAnyPublisher()
    }
}
