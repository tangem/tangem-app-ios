//
//  TezosJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemNetworkUtils

class TezosJsonRpcProvider: HostProvider {
    var host: String {
        nodeInfo.host
    }

    private let nodeInfo: NodeInfo
    private let provider: TangemProvider<TezosTarget>

    init(nodeInfo: NodeInfo, configuration: TangemProviderConfiguration) {
        self.nodeInfo = nodeInfo
        provider = TangemProvider<TezosTarget>(configuration: configuration)
    }

    func getInfo(address: String) -> AnyPublisher<TezosAddressResponse, Error> {
        requestPublisher(for: TezosTarget(node: nodeInfo, endpoint: .addressData(address: address)))
            .map(TezosAddressResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func checkPublicKeyRevealed(address: String) -> AnyPublisher<Bool, Error> {
        requestPublisher(for: TezosTarget(node: nodeInfo, endpoint: .managerKey(address: address)))
            .mapString()
            .cleanString()
            .map { $0 == "null" ? false : true }
            .tryCatch { error -> AnyPublisher<Bool, Error> in
                if case MoyaError.stringMapping = error {
                    return Just(false)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                throw error
            }
            .eraseToAnyPublisher()
    }

    func getHeader() -> AnyPublisher<TezosHeaderResponse, Error> {
        requestPublisher(for: TezosTarget(node: nodeInfo, endpoint: .getHeader))
            .map(TezosHeaderResponse.self)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func forgeContents(headerHash: String, contents: [TezosOperationContent]) -> AnyPublisher<String, Error> {
        let body = TezosForgeBody(branch: headerHash, contents: contents)

        return requestPublisher(for: TezosTarget(node: nodeInfo, endpoint: .forgeOperations(body: body)))
            .mapString()
            .cleanString()
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func checkTransaction(
        protocol: String,
        hash: String,
        contents: [TezosOperationContent],
        signature: String
    ) -> AnyPublisher<Response, Error> {
        let body = TezosPreapplyBody(
            protocol: `protocol`,
            branch: hash,
            contents: contents,
            signature: signature
        )

        return requestPublisher(for: TezosTarget(node: nodeInfo, endpoint: .preapplyOperations(body: [body])))
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    func sendTransaction(_ transaction: String) -> AnyPublisher<Response, Error> {
        requestPublisher(for: TezosTarget(node: nodeInfo, endpoint: .sendTransaction(tx: transaction)))
            .mapError { $0 }
            .eraseToAnyPublisher()
    }

    private func requestPublisher(for target: TezosTarget) -> AnyPublisher<Response, MoyaError> {
        provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .eraseToAnyPublisher()
    }
}
