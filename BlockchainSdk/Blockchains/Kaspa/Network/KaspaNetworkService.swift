//
//  KaspaNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkService: MultiNetworkProvider {
    let providers: [KaspaNetworkProvider]
    var currentProviderIndex: Int = 0

    private let blockchain: Blockchain

    init(providers: [KaspaNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }

    func getInfo(address: String, unconfirmedTransactionHashes: [String]) -> AnyPublisher<KaspaAddressInfo, Error> {
        balance(address: address)
            .zip(utxos(address: address), confirmedTransactionHashes(unconfirmedTransactionHashes))
            .tryMap { [weak self] balance, utxos, confirmedTransactionHashes in
                guard let self else { throw WalletError.empty }

                let unspentOutputs: [BitcoinUnspentOutput] = utxos.compactMap {
                    guard
                        let amount = UInt64($0.utxoEntry.amount)
                    else {
                        return nil
                    }

                    return BitcoinUnspentOutput(
                        transactionHash: $0.outpoint.transactionId,
                        outputIndex: $0.outpoint.index,
                        amount: amount,
                        outputScript: $0.utxoEntry.scriptPublicKey.scriptPublicKey
                    )
                }

                return KaspaAddressInfo(
                    balance: Decimal(integerLiteral: balance.balance) / blockchain.decimalValue,
                    unspentOutputs: unspentOutputs,
                    confirmedTransactionHashes: confirmedTransactionHashes
                )
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: KaspaTransactionRequest) -> AnyPublisher<KaspaTransactionResponse, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
        }
    }

    private func currentBlueScore() -> AnyPublisher<UInt64, Error> {
        providerPublisher {
            $0.currentBlueScore()
                .map(\.blueScore)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    private func balance(address: String) -> AnyPublisher<KaspaBalanceResponse, Error> {
        providerPublisher {
            $0.balance(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    private func utxos(address: String) -> AnyPublisher<[KaspaUnspentOutputResponse], Error> {
        providerPublisher {
            $0.utxos(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    private func confirmedTransactionHashes(_ hashes: [String]) -> AnyPublisher<[String], Error> {
        if hashes.isEmpty {
            return .justWithError(output: [])
        }

        let confirmedTransactionBlueScoreDifference: UInt64 = 10

        return Publishers.Zip(currentBlueScore(), transactionInfos(hashes: hashes))
            .map { currentBlueScore, transactionInfos in
                let confirmedTransactions = transactionInfos.filter {
                    $0.isAccepted
                        &&
                        currentBlueScore > ($0.acceptingBlockBlueScore + confirmedTransactionBlueScoreDifference)
                }

                return confirmedTransactions.map(\.transactionId)
            }
            .eraseToAnyPublisher()
    }

    private func transactionInfos(hashes: [String]) -> AnyPublisher<[KaspaTransactionInfoResponse], Error> {
        hashes
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] hash -> AnyPublisher<KaspaTransactionInfoResponse, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }

                return transactionInfo(hash: hash)
                    .replaceError(with: .init(transactionId: hash, isAccepted: false, acceptingBlockBlueScore: 0))
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .collect()
            .eraseToAnyPublisher()
    }

    private func transactionInfo(hash: String) -> AnyPublisher<KaspaTransactionInfoResponse, Error> {
        providerPublisher {
            $0.transactionInfo(hash: hash)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }

    func mass(data: KaspaTransactionData) -> AnyPublisher<KaspaMassResponse, Error> {
        providerPublisher { provider in
            provider.mass(data: data)
        }
    }

    func feeEstimate() -> AnyPublisher<KaspaFeeEstimateResponse, Error> {
        providerPublisher { provider in
            provider.feeEstimate()
        }
    }
}
