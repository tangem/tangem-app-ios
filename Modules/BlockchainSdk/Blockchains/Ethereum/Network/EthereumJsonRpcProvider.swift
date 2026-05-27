//
//  EthereumJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import Moya
import TangemNetworkUtils

final class EthereumJsonRpcProvider: HostProvider {
    private let node: NodeInfo
    private let provider: TangemProvider<EthereumTarget>
    private let networkPrefix: EthereumTarget.RPCNetworkPrefix

    let networkProviderType: NetworkProviderType?

    var host: String {
        node.url.hostOrUnknown
    }

    init(
        node: NodeInfo,
        configuration: TangemProviderConfiguration,
        networkPrefix: EthereumTarget.RPCNetworkPrefix,
        networkProviderType: NetworkProviderType?
    ) {
        self.node = node
        provider = TangemProvider<EthereumTarget>(configuration: configuration)
        self.networkPrefix = networkPrefix
        self.networkProviderType = networkProviderType
    }

    func call(contractAddress: String, encodedData: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .call(params: .init(to: contractAddress, data: encodedData)))
    }

    func getBalance(for address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .balance(address: address))
    }

    func getTxCount(for address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .transactions(address: address))
    }

    func getPendingTxCount(for address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .pending(address: address))
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .send(transaction: transaction))
    }

    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<String, Error> {
        requestPublisher(for: .gasLimit(params: .init(to: to, from: from, value: value, data: data)))
    }

    func getGasPrice() -> AnyPublisher<String, Error> {
        requestPublisher(for: .gasPrice)
    }

    func getPriorityFee() -> AnyPublisher<String, Error> {
        requestPublisher(for: .priorityFee)
    }

    func getFeeHistory() -> AnyPublisher<EthereumFeeHistoryResponse, Error> {
        requestPublisher(for: .feeHistory)
    }

    func getTransactionByHash(_ hash: String) -> AnyPublisher<EthereumTransaction?, Error> {
        requestPublisher(for: .getTransactionByHash(hash))
    }

    private func requestPublisher<Result: Decodable>(for targetType: EthereumTarget.EthereumTargetType) -> AnyPublisher<Result, Error> {
        let target = EthereumTarget(targetType: targetType, node: node, networkPrefix: networkPrefix)

        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(JSONRPC.Response<Result, JSONRPC.APIError>.self)
            .tryMap { try $0.result.get() }
            .eraseToAnyPublisher()
    }
}
