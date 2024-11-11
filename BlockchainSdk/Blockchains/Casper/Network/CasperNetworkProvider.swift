//
//  CasperNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class CasperNetworkProvider: HostProvider {
    var host: String {
        node.url.absoluteString
    }

    // MARK: - Private Properties

    private let node: NodeInfo
    private let provider: NetworkProvider<CasperTarget>

    // MARK: - Init

    init(
        node: NodeInfo,
        configuration: NetworkProviderConfiguration
    ) {
        self.node = node
        provider = NetworkProvider<CasperTarget>(configuration: configuration)
    }

    // MARK: - Implementation

    func getBalance(address: String) -> AnyPublisher<CasperNetworkResponse.Balance, Error> {
        let query = CasperNetworkRequest.QueryBalance(purseIdentifier: .init(mainPurseUnderPublicKey: address))
        return requestPublisher(for: .getBalance(data: query))
    }

    func putDeploy(rawJSON: Data) -> AnyPublisher<CasperNetworkResponse.Transaction, Error> {
        return requestPublisher(for: .putDeploy(data: rawJSON))
    }

    // MARK: - Private Implementation

    private func requestPublisher<T: Decodable>(for type: CasperTarget.TargetType) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(CasperTarget(node: node, type: type))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<T, JSONRPC.APIError>.self, using: decoder)
            .tryMap {
                try $0.result.get()
            }
            .eraseToAnyPublisher()
    }
}
