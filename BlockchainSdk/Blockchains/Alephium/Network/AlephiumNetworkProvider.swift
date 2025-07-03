//
//  AlephiumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNetworkUtils

struct AlephiumNetworkProvider: HostProvider {
    /// Blockchain API host
    var host: String {
        node.url.hostOrUnknown
    }

    /// Configuration connection node for provider
    private let node: NodeInfo

    // MARK: - Properties

    /// Network provider of blockchain
    private let provider: TangemProvider<AlephiumProviderTarget>

    // MARK: - Init

    init(
        node: NodeInfo,
        networkConfig: TangemProviderConfiguration
    ) {
        self.node = node
        provider = .init(configuration: networkConfig)
    }

    // MARK: - Implementation

    func getBalance(address: String) -> AnyPublisher<AlephiumNetworkResponse.Balance, Error> {
        requestPublisher(for: .init(node: node, targetType: .getBalance(address: address)))
    }

    func getUTXOs(address: String) -> AnyPublisher<AlephiumNetworkResponse.UTXOs, Error> {
        requestPublisher(for: .init(node: node, targetType: .getUTXO(address: address)))
    }

    func buildTransaction(
        transfer: AlephiumNetworkRequest.BuildTransferTx
    ) -> AnyPublisher<AlephiumNetworkResponse.BuildTransferTxResult, Error> {
        requestPublisher(for: .init(node: node, targetType: .buildTransaction(transfer)))
    }

    func submit(transaction: AlephiumNetworkRequest.Submit) -> AnyPublisher<AlephiumNetworkResponse.Submit, Error> {
        requestPublisher(for: .init(node: node, targetType: .submitTransaction(transaction)))
    }

    func transactionStatus(by id: String) -> AnyPublisher<AlephiumNetworkResponse.Status, Error> {
        requestPublisher(for: .init(node: node, targetType: .transactionStatus(txId: id)))
    }

    // MARK: - Private Implementation

    private func requestPublisher<T: Decodable>(for target: AlephiumProviderTarget) -> AnyPublisher<T, any Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .mapError { _ in BlockchainSdkError.empty }
            .eraseToAnyPublisher()
    }
}
