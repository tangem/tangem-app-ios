//
// SuiNetworkProvider.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNetworkUtils

final class SuiNetworkProvider: HostProvider {
    var host: String {
        node.host
    }

    private let node: NodeInfo
    private let provider: TangemProvider<SuiTarget>

    init(node: NodeInfo, networkConfiguration: TangemProviderConfiguration) {
        self.node = node
        provider = TangemProvider<SuiTarget>(configuration: networkConfiguration)
    }

    func getBalance(address: String, coin: String, cursor: String?) -> AnyPublisher<SuiGetCoins, Error> {
        requestPublisher(for: .getBalance(address: address, cursor: cursor))
    }

    func getReferenceGasPrice() -> AnyPublisher<SuiReferenceGasPrice, Error> {
        requestPublisher(for: .getReferenceGasPrice)
    }

    func dryRunTransaction(transaction raw: String) -> AnyPublisher<SuiInspectTransaction, Error> {
        requestPublisher(for: .dryRunTransaction(transaction: raw))
    }

    func sendTransaction(transaction raw: String, signature: String) -> AnyPublisher<SuiExecuteTransaction, Error> {
        requestPublisher(for: .sendTransaction(transaction: raw, signature: signature))
    }

    func requestPublisher<Response: Codable>(for request: SuiTarget.Request) -> AnyPublisher<Response, Error> {
        provider
            .requestPublisher(SuiTarget(baseURL: node.url, request: request))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<Response, JSONRPC.APIError>.self)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
