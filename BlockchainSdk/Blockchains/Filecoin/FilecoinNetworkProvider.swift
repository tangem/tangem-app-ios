//
//  FilecoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemNetworkUtils

final class FilecoinNetworkProvider: HostProvider {
    var host: String {
        node.url.absoluteString
    }

    private let node: NodeInfo
    private let provider: TangemProvider<FilecoinTarget>

    init(
        node: NodeInfo,
        configuration: TangemProviderConfiguration
    ) {
        self.node = node
        provider = TangemProvider<FilecoinTarget>(configuration: configuration)
    }

    func getActorInfo(address: String) -> AnyPublisher<FilecoinResponse.GetActorInfo, Error> {
        requestPublisher(for: .getActorInfo(address: address))
    }

    func getEstimateMessageGas(message: FilecoinMessage) -> AnyPublisher<FilecoinResponse.GetEstimateMessageGas, Error> {
        requestPublisher(for: .getEstimateMessageGas(message: message))
    }

    func submitTransaction(signedMessage: FilecoinSignedMessage) -> AnyPublisher<FilecoinResponse.SubmitTransaction, Error> {
        requestPublisher(for: .submitTransaction(signedMessage: signedMessage))
    }

    private func requestPublisher<T: Decodable>(for target: FilecoinTarget.FilecoinTargetType) -> AnyPublisher<T, Error> {
        provider.requestPublisher(FilecoinTarget(node: node, target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<T, JSONRPC.APIError>.self)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
