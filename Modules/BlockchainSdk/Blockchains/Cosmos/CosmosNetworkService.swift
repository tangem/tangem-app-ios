//
//  CosmosNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CosmosNetworkService: MultiNetworkProvider {
    let providers: [CosmosRestProvider]
    var currentProviderIndex: Int = 0

    private let cosmosChain: CosmosChain

    let blockchainName: String

    init(cosmosChain: CosmosChain, providers: [CosmosRestProvider]) {
        self.providers = providers
        self.cosmosChain = cosmosChain
        blockchainName = cosmosChain.blockchainName
    }

    func accountInfo(for address: String, tokens: [Token], transactionHashes: [String]) -> AnyPublisher<CosmosAccountInfo, Error> {
        let cw20Tokens: [Token]
        if cosmosChain.allowCW20Tokens {
            cw20Tokens = tokens
        } else {
            cw20Tokens = []
        }

        return providerPublisher { [weak self] provider in
            guard let self else {
                return .anyFail(error: BlockchainSdkError.empty)
            }

            return provider.accounts(address: address)
                .zip(
                    provider.balances(address: address),
                    cw20TokenBalances(walletAddress: address, tokens: cw20Tokens),
                    confirmedTransactionHashes(transactionHashes, with: provider)
                )
                .withWeakCaptureOf(self)
                .tryMap { service, input in
                    let (accountInfo, balanceInfo, cw20TokenBalances, confirmedTransactionHashes) = input

                    guard let sequenceNumber = UInt64(accountInfo?.account.sequence ?? "0") else {
                        throw BlockchainSdkError.failedToParseNetworkResponse()
                    }

                    let accountNumber: UInt64?
                    if let account = accountInfo?.account {
                        accountNumber = UInt64(account.accountNumber)
                    } else {
                        accountNumber = nil
                    }

                    let chain = service.cosmosChain
                    let rawAmount = try service.parseBalance(
                        balanceInfo,
                        denomination: chain.smallestDenomination,
                        decimalValue: chain.blockchain.decimalValue
                    )
                    let amount = Amount(with: chain.blockchain, value: rawAmount)

                    let tokenAmounts: [Token: Decimal]
                    if chain.allowCW20Tokens {
                        tokenAmounts = cw20TokenBalances
                    } else {
                        tokenAmounts = Dictionary(try tokens.compactMap { token in
                            guard let denomination = chain.tokenDenomination(contractAddress: token.contractAddress, tokenCurrencySymbol: token.symbol) else {
                                return nil
                            }

                            let balance = try service.parseBalance(balanceInfo, denomination: denomination, decimalValue: token.decimalValue)
                            return (token, balance)
                        }, uniquingKeysWith: {
                            pair1, _ in
                            pair1
                        })
                    }

                    return CosmosAccountInfo(
                        accountNumber: accountNumber,
                        sequenceNumber: sequenceNumber,
                        amount: amount,
                        tokenBalances: tokenAmounts,
                        confirmedTransactionHashes: confirmedTransactionHashes
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func nativeBalance(for address: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { [weak self] provider in
            provider.balances(address: address)
                .tryMap { balanceInfo -> Decimal in
                    guard let self else {
                        throw BlockchainSdkError.empty
                    }

                    let chain = self.cosmosChain

                    return try self.parseBalance(
                        balanceInfo,
                        denomination: chain.smallestDenomination,
                        decimalValue: chain.blockchain.decimalValue
                    )
                }
                .eraseToAnyPublisher()
        }
    }

    func estimateGas(for transaction: Data) -> AnyPublisher<UInt64, Error> {
        providerPublisher { provider in
            provider.simulate(data: transaction)
                .map(\.gasInfo.gasUsed)
                .tryMap { rawGasUsed in
                    guard let gasUsed = UInt64(rawGasUsed) else {
                        throw BlockchainSdkError.failedToGetFee
                    }

                    return gasUsed
                }
                .eraseToAnyPublisher()
        }
    }

    func send(transaction: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.txs(data: transaction)
                .map(\.txResponse)
                .tryMap { txResponse in
                    guard txResponse.code == 0 else {
                        throw BlockchainSdkError.failedToSendTx
                    }

                    return txResponse.txhash
                }
                .eraseToAnyPublisher()
        }
    }

    private func cw20TokenBalances(walletAddress: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { service, token -> AnyPublisher<(Token, Decimal), Error> in
                return service.cw20TokenBalance(walletAddress: walletAddress, token: token)
            }
            .collect()
            .map { Dictionary($0) { pair1, _ in pair1 } }
            .eraseToAnyPublisher()
    }

    private func cw20TokenBalance(walletAddress: String, token: Token) -> AnyPublisher<(Token, Decimal), Error> {
        let request = CosmosCW20BalanceRequest(address: walletAddress)
        guard let query = try? JSONEncoder().encode(request) else {
            return .anyFail(error: BlockchainSdkError.failedToParseNetworkResponse())
        }

        return providerPublisher { provider in
            provider.querySmartContract(contractAddress: token.contractAddress, query: query)
                .tryMap {
                    (result: CosmosCW20QueryResult<CosmosCW20QueryBalanceData>) -> (Token, Decimal) in
                    guard let balanceInSmallestDenomination = Decimal(string: result.data.balance) else {
                        throw BlockchainSdkError.failedToParseNetworkResponse()
                    }

                    let balance = balanceInSmallestDenomination / token.decimalValue
                    return (token, balance)
                }
                .eraseToAnyPublisher()
        }
    }

    private func confirmedTransactionHashes(_ hashes: [String], with provider: CosmosRestProvider) -> AnyPublisher<[String], Error> {
        hashes
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { service, hash -> AnyPublisher<String?, Error> in
                return service.transactionConfirmed(hash, with: provider)
            }
            .collect()
            .map { $0.compactMap { $0 } }
            .eraseToAnyPublisher()
    }

    private func transactionConfirmed(_ hash: String, with provider: CosmosRestProvider) -> AnyPublisher<String?, Error> {
        provider.transactionStatus(hash: hash)
            .map(\.txResponse)
            .compactMap { response in
                if let height = UInt64(response.height),
                   height > 0 {
                    return hash
                } else {
                    return nil
                }
            }
            .tryCatch { error -> AnyPublisher<String?, Error> in
                if case BlockchainSdkError.failedToParseNetworkResponse = error {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                throw error
            }
            .eraseToAnyPublisher()
    }

    private func parseBalance(_ balanceInfo: CosmosBalanceResponse, denomination: String, decimalValue: Decimal) throws -> Decimal {
        guard let balanceAmountString = balanceInfo.balances.first(where: { $0.denom == denomination })?.amount else {
            return .zero
        }

        guard let balanceInSmallestDenomination = Int(balanceAmountString) else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        return Decimal(balanceInSmallestDenomination) / decimalValue
    }
}
