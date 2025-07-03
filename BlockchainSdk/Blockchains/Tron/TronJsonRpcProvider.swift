//
//  TronJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import TangemNetworkUtils

class TronJsonRpcProvider: HostProvider {
    var host: String {
        node.url.absoluteString + (node.headers?.headerValue == nil ? "" : " (API KEY)")
    }

    private let node: NodeInfo
    private let provider: TangemProvider<TronTarget>

    init(node: NodeInfo, configuration: TangemProviderConfiguration) {
        self.node = node
        provider = TangemProvider<TronTarget>(configuration: configuration)
    }

    func getChainParameters() -> AnyPublisher<TronGetChainParametersResponse, Error> {
        requestPublisher(for: .getChainParameters)
    }

    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        requestPublisher(for: .getAccount(address: address))
    }

    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        requestPublisher(for: .getAccountResource(address: address))
    }

    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        requestPublisher(for: .getNowBlock)
    }

    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        requestPublisher(for: .broadcastHex(data: data))
    }

    func tokenBalance(address: String, contractAddress: String, parameter: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        requestPublisher(for: .tokenBalance(address: address, contractAddress: contractAddress, parameter: parameter))
    }

    func contractEnergyUsage(sourceAddress: String, contractAddress: String, parameter: String) -> AnyPublisher<TronContractEnergyUsageResponse, Error> {
        requestPublisher(for: .contractEnergyUsage(sourceAddress: sourceAddress, contractAddress: contractAddress, parameter: parameter))
    }

    func transactionInfo(id: String) -> AnyPublisher<TronTransactionInfoResponse, Error> {
        requestPublisher(for: .getTransactionInfoById(transactionID: id))
    }

    func getAllowance(sourceAddress: String, contractAddress: String, parameter: String) -> AnyPublisher<TronTriggerSmartContractResponse, Error> {
        requestPublisher(for: .getAllowance(sourceAddress: sourceAddress, contractAddress: contractAddress, parameter: parameter))
    }

    private func requestPublisher<T: Decodable>(for target: TronTarget.TronTargetType) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(TronTarget(node: node, target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .mapError { moyaError in
                if case .objectMapping(_, let response) = moyaError {
                    return BlockchainSdkError.failedToParseNetworkResponse(response)
                }
                return moyaError
            }
            .eraseToAnyPublisher()
    }
}
