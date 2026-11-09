//
//  TronNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BigInt

class TronNetworkService: MultiNetworkProvider {
    let providers: [TronJsonRpcProvider]
    var currentProviderIndex: Int = 0

    let isTestnet: Bool

    private var blockchain: Blockchain {
        Blockchain.tron(testnet: isTestnet)
    }

    var blockchainName: String {
        blockchain.displayName
    }

    init(isTestnet: Bool, providers: [TronJsonRpcProvider]) {
        self.isTestnet = isTestnet
        self.providers = providers
    }

    func chainParameters() -> AnyPublisher<TronChainParameters, Error> {
        providerPublisher { provider in
            provider.getChainParameters()
                .tryMap { response in
                    guard
                        let energyFeeChainParameter = response.chainParameter.first(where: { $0.key == "getEnergyFee" }),
                        let energyFee = energyFeeChainParameter.value,
                        let dynamicEnergyMaxFactorChainParameter = response.chainParameter.first(where: { $0.key == "getDynamicEnergyMaxFactor" }),
                        let dynamicEnergyMaxFactor = dynamicEnergyMaxFactorChainParameter.value,
                        let dynamicEnergyIncreaseFactorParameter = response.chainParameter.first(where: { $0.key == "getDynamicEnergyIncreaseFactor" }),
                        let dynamicEnergyIncreaseFactor = dynamicEnergyIncreaseFactorParameter.value
                    else {
                        throw BlockchainSdkError.failedToParseNetworkResponse()
                    }

                    // Absent on chains that predate the memo-fee proposal.
                    let memoFee = response.chainParameter.first(where: { $0.key == "getMemoFee" })?.value ?? 0

                    return TronChainParameters(
                        sunPerEnergyUnit: energyFee,
                        dynamicEnergyMaxFactor: dynamicEnergyMaxFactor,
                        dynamicEnergyIncreaseFactor: dynamicEnergyIncreaseFactor,
                        memoFee: memoFee
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func accountInfo(for address: String, tokens: [Token], transactionIDs: [String]) -> AnyPublisher<TronAccountInfo, Error> {
        Publishers.Zip3(
            getAccount(for: address),
            tokenBalances(address: address, tokens: tokens),
            confirmedTransactionIDs(ids: transactionIDs)
        )
        .map { [blockchain] accountInfo, tokenBalances, confirmedTransactionIDs in
            let balance = Decimal(accountInfo.balance ?? 0) / blockchain.decimalValue
            return TronAccountInfo(
                balance: balance,
                tokenBalances: tokenBalances,
                confirmedTransactionIDs: confirmedTransactionIDs
            )
        }
        .eraseToAnyPublisher()
    }

    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        providerPublisher { provider in
            provider.getNowBlock()
        }
    }

    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        providerPublisher { provider in
            provider.broadcastHex(data)
        }
    }

    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        providerPublisher { provider in
            provider.getAccountResource(for: address)
                .mapError { error in
                    if case BlockchainSdkError.failedToParseNetworkResponse(let response) = error,
                       let data = response?.data,
                       let string = String(data: data, encoding: .utf8),
                       string.trimmingCharacters(in: .whitespacesAndNewlines) == "{}" {
                        return BlockchainSdkError.accountNotActivated
                    }
                    return error
                }
                .eraseToAnyPublisher()
        }
    }

    func getAccountInfoByAddress(_ address: String) -> AnyPublisher<TronAccountInfoByAddress, Error> {
        providerPublisher { provider in
            provider.getAccountInfoByAddress(address)
        }
        .map { [blockchain] response in
            let account = response.data.first
            let balance = Decimal(account?.balance ?? 0) / blockchain.decimalValue

            let tokenBalances = account?.trc20?.reduce(into: [String: Decimal]()) { result, balancesByContract in
                for (contractAddress, rawBalance) in balancesByContract {
                    guard let balance = Decimal(string: rawBalance) else {
                        continue
                    }

                    result[contractAddress, default: .zero] += balance
                }
            } ?? [:]

            return TronAccountInfoByAddress(
                balance: balance,
                tokenBalances: tokenBalances
            )
        }
        .eraseToAnyPublisher()
    }

    func accountExists(address: String) -> AnyPublisher<Bool, Error> {
        providerPublisher { provider in
            provider.getAccount(for: address)
                .map { _ in
                    true
                }
                .tryCatch { error in
                    if case BlockchainSdkError.failedToParseNetworkResponse = error {
                        return Just(false)
                    }
                    throw error
                }
                .eraseToAnyPublisher()
        }
    }

    func contractEnergyUsage(sourceAddress: String, contractAddress: String, contractEnergyUsageData: String) -> AnyPublisher<Int, Error> {
        providerPublisher { provider in
            provider.contractEnergyUsage(sourceAddress: sourceAddress, contractAddress: contractAddress, parameter: contractEnergyUsageData)
                .map(\.energy_used)
                .eraseToAnyPublisher()
        }
    }

    func contractEnergyUsage(sourceAddress: String, contractAddress: String, callDataHex: String, callValue: UInt64) -> AnyPublisher<Int, Error> {
        providerPublisher { provider in
            provider.contractEnergyUsageForCallData(sourceAddress: sourceAddress, contractAddress: contractAddress, data: callDataHex, callValue: callValue)
                .map(\.energy_used)
                .eraseToAnyPublisher()
        }
    }

    func getAllowance(owner: String, contractAddress: String, allowanceData: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            provider.getAllowance(sourceAddress: owner, contractAddress: contractAddress, parameter: allowanceData)
                .tryMap { response in
                    // [REDACTED_TODO_COMMENT]
                    try TronUtils().parseBalance(
                        response: response.constant_result,
                        decimals: 0
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Private Implementation

    private func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        providerPublisher { provider in
            provider.getAccount(for: address)
                .tryCatch { error in
                    if case BlockchainSdkError.failedToParseNetworkResponse = error {
                        return Just(TronGetAccountResponse(balance: 0, address: address))
                    }
                    throw error
                }
                .eraseToAnyPublisher()
        }
    }

    private func tokenBalances(address: String, tokens: [Token]) -> AnyPublisher<[Token: Result<Decimal, Error>], Error> {
        Result {
            try TronUtils().convertAddressToBytesPadded(address).hex()
        }
        .publisher
        .flatMap { encodedAddressData in
            tokens
                .publisher
                .setFailureType(to: Error.self)
                .map { (encodedAddressData, $0) }
        }
        .withWeakCaptureOf(self)
        .flatMap { service, args in
            let (encodedAddressData, token) = args

            return service.tokenBalance(address: address, token: token, encodedAddressData: encodedAddressData)
        }
        .collect()
        .map { balances in
            balances.reduce(into: [:]) { tokenBalances, tokenBalance in
                let (token, balance) = tokenBalance
                tokenBalances[token] = balance
            }
        }
        .eraseToAnyPublisher()
    }

    private func tokenBalance(address: String, token: Token, encodedAddressData: String) -> AnyPublisher<(Token, Result<Decimal, Error>), Never> {
        providerPublisher { provider in
            provider.tokenBalance(address: address, contractAddress: token.contractAddress, parameter: encodedAddressData)
                .tryMap { response in
                    try TronUtils().parseBalance(
                        response: response.constant_result,
                        decimals: token.decimalCount
                    )
                }
                .eraseToAnyPublisher()
        }
        .mapToResult()
        .map { (token, $0) }
        .eraseToAnyPublisher()
    }

    private func confirmedTransactionIDs(ids transactionIDs: [String]) -> AnyPublisher<[String], Error> {
        transactionIDs
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] transactionID -> AnyPublisher<String?, Error> in
                guard let self = self else {
                    return .anyFail(error: BlockchainSdkError.empty)
                }
                return transactionConfirmed(id: transactionID)
            }
            .collect()
            .map { confirmations in
                confirmations.reduce(into: []) { confirmedTransactionIDs, confirmedTransactionID in
                    if let confirmedTransactionID = confirmedTransactionID {
                        confirmedTransactionIDs.append(confirmedTransactionID)
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    private func transactionConfirmed(id: String) -> AnyPublisher<String?, Error> {
        providerPublisher { provider in
            provider.transactionInfo(id: id)
                .map { _ in
                    return id
                }
                .tryCatch { error in
                    if case BlockchainSdkError.failedToParseNetworkResponse = error {
                        return Just<String?>(nil)
                    }
                    throw error
                }
                .eraseToAnyPublisher()
        }
    }
}
