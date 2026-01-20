//
//  EthereumNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import CombineExt
import BigInt
import TangemFoundation

class EthereumNetworkService: MultiNetworkProvider {
    let providers: [EthereumJsonRpcProvider]
    var currentProviderIndex: Int = 0

    let blockchainName: String

    private let decimals: Int
    private let abiEncoder: ABIEncoder

    init(
        decimals: Int,
        providers: [EthereumJsonRpcProvider],
        abiEncoder: ABIEncoder,
        blockchainName: String
    ) {
        self.providers = providers
        self.decimals = decimals
        self.abiEncoder = abiEncoder
        self.blockchainName = blockchainName
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
        }
    }

    func getPendingTransactionsInfo(address: String, pendingTransactionHashes: [String]) -> AnyPublisher<EthereumPendingTransactionsInfo, Error> {
        Publishers.Zip3(
            getPendingTransactionStatuses(pendingTransactionHashes),
            getTxCount(address),
            getPendingTxCount(address)
        )
        .map { EthereumPendingTransactionsInfo(statuses: $0, transactionCount: $1, pendingTransactionCount: $2) }
        .eraseToAnyPublisher()
    }

    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<EthereumInfoResponse, Error> {
        Publishers.Zip(
            getBalance(address),
            getTokensBalance(address, tokens: tokens)
        )
        .map { EthereumInfoResponse(balance: $0, tokenBalances: $1) }
        .eraseToAnyPublisher()
    }

    func getEIP1559Fee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumEIP1559FeeResponse, Error> {
        let gasLimitPublisher = getGasLimit(to: to, from: from, value: value, data: data)
        let feeHistoryPublisher = getFeeHistory()

        return Publishers.Zip(gasLimitPublisher, feeHistoryPublisher)
            .map { gasLimit, feeHistory -> EthereumEIP1559FeeResponse in
                return EthereumMapper.mapToEthereumEIP1559FeeResponse(
                    gasLimit: gasLimit,
                    feeHistory: feeHistory
                )
            }
            .mapError { EthereumMapper.mapError($0) }
            .eraseToAnyPublisher()
    }

    func getLegacyFee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumLegacyFeeResponse, Error> {
        let gasPricePublisher = getGasPrice()
        let gasLimitPublisher = getGasLimit(to: to, from: from, value: value, data: data)

        return Publishers.Zip(gasPricePublisher, gasLimitPublisher)
            .tryMap { gasPrice, gasLimit -> EthereumLegacyFeeResponse in
                return EthereumMapper.mapToEthereumLegacyFeeResponse(
                    gasPrice: gasPrice,
                    gasLimit: gasLimit
                )
            }
            .mapError { EthereumMapper.mapError($0) }
            .eraseToAnyPublisher()
    }

    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        providerPublisher { provider in
            provider.getTxCount(for: address)
                .tryMap { try EthereumMapper.mapInt($0) }
                .eraseToAnyPublisher()
        }
    }

    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> {
        providerPublisher {
            $0.getFeeHistory()
                .tryMap { try EthereumMapper.mapFeeHistory($0) }
                .tryCatch { [weak self] error -> AnyPublisher<EthereumFeeHistory, Error> in
                    guard let self else {
                        throw error
                    }

                    if case ETHError.failedToParseFeeHistory = error {
                        return getGasPrice()
                            .map { EthereumMapper.mapFeeHistoryFallback(gasPrice: $0) }
                            .eraseToAnyPublisher()
                    }

                    throw error
                }
                .eraseToAnyPublisher()
        }
    }

    func getPriorityFee() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getPriorityFee()
                .tryMap { try EthereumMapper.mapBigUInt($0) }
                .eraseToAnyPublisher()
        }
    }

    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasPrice()
                .tryMap { try EthereumMapper.mapBigUInt($0) }
                .eraseToAnyPublisher()
        }
    }

    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasLimit(to: to, from: from, value: value, data: data)
                .tryMap { try EthereumMapper.mapBigUInt($0) }
                .eraseToAnyPublisher()
        }
    }

    func getTokensBalance(
        _ address: String,
        tokens: [Token]
    ) -> AnyPublisher<[Token: Result<Decimal, Error>], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { networkService, token -> AnyPublisher<(Token, Result<Decimal, Error>), Error> in
                networkService.getTokenBalance(
                    address: address,
                    token: token
                )
            }
            .collect()
            .map { $0.reduce(into: [Token: Result<Decimal, Error>]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }

    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<String, Error> {
        let method = AllowanceERC20TokenMethod(owner: owner, spender: spender)
        return providerPublisher {
            $0.call(contractAddress: contractAddress, encodedData: method.encodedData)
        }
    }

    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            provider.getBalance(for: address)
                .withWeakCaptureOf(self)
                .tryMap { networkService, result in
                    guard let value = EthereumUtils.parseEthereumDecimal(result, decimalsCount: networkService.decimals) else {
                        throw ETHError.failedToParseBalance(value: result, address: address, decimals: networkService.decimals)
                    }

                    return value
                }
                .eraseToAnyPublisher()
        }
    }

    func getPendingTransactionStatuses(_ hashes: [String]) -> AnyPublisher<[String: PendingTransactionStatus], Error> {
        hashes.publisher
            .withWeakCaptureOf(self)
            .flatMap { networkService, hash in
                return networkService.getTransactionStatus(hash: hash)
            }
            .collect()
            .map { statuses in
                statuses.reduce(into: [:]) { partialResult, status in
                    partialResult[status.0] = status.1
                }
            }
            .eraseToAnyPublisher()
    }

    func getTransactionStatus(hash: String) -> AnyPublisher<(String, PendingTransactionStatus), Error> {
        getTransactionByHash(hash)
            .map { transaction in
                var status: PendingTransactionStatus {
                    guard let transaction else { return .dropped }
                    return transaction.blockNumber == nil ? .pending : .executed
                }

                return (hash, status)
            }
            .eraseToAnyPublisher()
    }

    func getTransactionByHash(_ hash: String) -> AnyPublisher<EthereumTransaction?, Error> {
        providerPublisher {
            $0.getTransactionByHash(hash)
        }
    }

    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getPendingTxCount(for: address)
                .tryMap { try EthereumMapper.mapInt($0) }
                .eraseToAnyPublisher()
        }
    }

    func resolveAddress(hash: Data, encode name: Data) -> AnyPublisher<String, Error> {
        let method = ReadEthereumAddressEIP137TokenMethod(nameBytes: name, hashBytes: hash)

        return providerPublisher {
            $0.call(contractAddress: method.contractAddress, encodedData: method.encodedData)
        }
        .tryMap { response in
            try ENSResponseConverter.convert(response)
        }
        .eraseToAnyPublisher()
    }

    func resolveDomainName(address: String) -> AnyPublisher<String, Error> {
        let method = ReadEthereumNameFromReverseRecordMethod(address: address)

        return providerPublisher {
            $0.call(contractAddress: method.contractAddress, encodedData: method.encodedData)
        }
        .tryMap { response in
            try ENSNameResponseConverter.convert(response)
        }
        .eraseToAnyPublisher()
    }

    func read<Method: SmartContractTargetMethodType>(contractAddress: String, method: Method) -> AnyPublisher<String, Error> {
        let encodedData = abiEncoder.encode(method: method.methodName, parameters: method.parameters)

        return providerPublisher {
            $0.call(contractAddress: contractAddress, encodedData: encodedData)
        }
    }
}

private extension EthereumNetworkService {
    func getTokenBalance(
        address: String,
        token: Token
    ) -> AnyPublisher<(Token, Result<Decimal, Error>), Error> {
        providerPublisher { provider -> AnyPublisher<Decimal, Error> in
            let method = TokenBalanceERC20TokenMethod(owner: address)

            return provider
                .call(contractAddress: token.contractAddress, encodedData: method.encodedData)
                .withWeakCaptureOf(self)
                .tryMap { networkService, result in
                    guard let value = EthereumUtils.parseEthereumDecimal(result, decimalsCount: token.decimalCount) else {
                        throw ETHError.failedToParseBalance(value: result, address: token.contractAddress, decimals: token.decimalCount)
                    }

                    return value
                }
                .eraseToAnyPublisher()
        }
        .mapToResult()
        .setFailureType(to: Error.self)
        .map { (token, $0) }
        .eraseToAnyPublisher()
    }
}

extension EthereumNetworkService: EVMSmartContractInteractor {
    func ethCall<Request>(request: Request) -> AnyPublisher<String, Error> where Request: SmartContractRequest {
        return providerPublisher {
            $0.call(contractAddress: request.contractAddress, encodedData: request.encodedData)
        }
    }
}
