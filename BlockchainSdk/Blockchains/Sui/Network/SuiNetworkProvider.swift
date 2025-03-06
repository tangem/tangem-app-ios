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
    private let node: NodeInfo
    private let provider: NetworkProvider<SuiTarget>

    let host: String

    init(node: NodeInfo, networkConfiguration: NetworkProviderConfiguration) {
        self.node = node
        provider = NetworkProvider<SuiTarget>(configuration: networkConfiguration)
        host = node.url.hostOrUnknown
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
