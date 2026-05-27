//
//  TONNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TonSwift
import BigInt
import TangemFoundation
import CombineExt

/// Abstract layer for multi provide TON blockchain
class TONNetworkService: MultiNetworkProvider {
    // MARK: - Protperties

    let providers: [TONProvider]
    var currentProviderIndex: Int = 0

    var blockchainName: String {
        blockchain.displayName
    }

    private var blockchain: Blockchain

    // MARK: - Init

    init(providers: [TONProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }

    // MARK: - Implementation

    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<TONWalletInfo, Error> {
        Publishers.Zip(
            getWalletInfo(address: address),
            getTokensInfo(address: address, tokens: tokens)
        )
        .tryMap { walletInfo, tokensInfo in
            guard let decimalBalance = Decimal(string: walletInfo.balance) else {
                throw BlockchainSdkError.failedToParseNetworkResponse()
            }

            return TONWalletInfo(
                balance: decimalBalance / self.blockchain.decimalValue,
                sequenceNumber: walletInfo.seqno ?? 0,
                isAvailable: walletInfo.accountState == .active,
                tokensInfo: tokensInfo
            )
        }
        .eraseToAnyPublisher()
    }

    func getJettonWalletAddress(for ownerAddress: String, token: Token) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.getJettonWalletAddress(
                for: ownerAddress,
                contractAddress: token.contractAddress
            )
            .tryMap { response in
                let reader = TupleReader(items: response.stack)
                let address = try reader.readAddress()

                return address.toString(bounceable: false)
            }
            .eraseToAnyPublisher()
        }
    }

    func isJettonWalletActive(jettonWalletAddress: String) -> AnyPublisher<Bool, Error> {
        providerPublisher { provider in
            provider.getAddressInformation(address: jettonWalletAddress)
                .map { info in
                    info.state == .active
                }
                .eraseToAnyPublisher()
        }
    }

    func getFee(
        source: String,
        destination: String,
        amount: Amount,
        message: String
    ) -> AnyPublisher<([Fee], String?), Error> {
        // Get recipient's jetton wallet address if sending tokens
        let recipientJettonWalletPublisher: AnyPublisher<String?, Error>
        if case .token(let token) = amount.type {
            // Recipient's jetton wallet address
            recipientJettonWalletPublisher = getJettonWalletAddress(
                for: destination,
                token: token
            )
            .map { $0 }
            .eraseToAnyPublisher()
        } else {
            recipientJettonWalletPublisher = Just(nil)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return Publishers.Zip(
            getFee(address: source, message: message),
            recipientJettonWalletPublisher
        )
        .eraseToAnyPublisher()
    }

    func send(message: String) -> AnyPublisher<String, Error> {
        return providerPublisher { provider in
            provider
                .send(message: message)
                .map(\.hash)
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Private Implementation

    private func getFee(address: String, message: String) -> AnyPublisher<[Fee], Error> {
        providerPublisher { provider in
            provider
                .getFee(address: address, body: message)
                .tryMap { [weak self] fee in
                    guard let self = self else {
                        throw BlockchainSdkError.empty
                    }

                    // Make rounded digits by correct for max amount Fee
                    let fee = fee.sourceFees.totalFee / blockchain.decimalValue
                    let roundedValue = fee.rounded(scale: 2, roundingMode: .up)
                    let feeAmount = Amount(with: blockchain, value: roundedValue)
                    return [Fee(feeAmount)]
                }
                .eraseToAnyPublisher()
        }
    }

    private func getWalletInfo(address: String) -> AnyPublisher<TONModels.Info, Error> {
        providerPublisher { provider in
            provider
                .getInfo(address: address)
        }
    }

    private func getTokensInfo(
        address: String,
        tokens: [Token]
    ) -> AnyPublisher<[Token: Result<TONWalletInfo.TokenInfo, Error>], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { networkService, token in
                networkService.getTokenInfo(address: address, token: token)
                    .mapToResult()
                    .setFailureType(to: Error.self)
                    .map { (token, $0) }
                    .eraseToAnyPublisher()
            }
            .collect()
            .map { $0.reduce(into: [Token: Result<TONWalletInfo.TokenInfo, Error>]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }

    private func getTokenInfo(address: String, token: Token) -> AnyPublisher<TONWalletInfo.TokenInfo, Error> {
        providerPublisher { provider in
            provider.getJettonWalletAddress(
                for: address,
                contractAddress: token.contractAddress
            )
            .tryMap { response in
                let reader = TupleReader(
                    items: response.stack
                )
                let address = try reader.readAddress()

                return address.toString(bounceable: false)
            }
            .flatMap { jettonWalletAddress in
                provider.getJettonWalledData(jettonWalletAddress: jettonWalletAddress)
                    .tryMap { response in
                        let reader = TupleReader(
                            items: response.stack
                        )

                        let bigAmount = (try? reader.readBigNumber()) ?? 0

                        guard let decimalAmount = bigAmount.decimal else {
                            throw BlockchainSdkError.failedToParseNetworkResponse(nil)
                        }

                        return TONWalletInfo.TokenInfo(
                            jettonWalletAddress: jettonWalletAddress,
                            balance: decimalAmount / token.decimalValue
                        )
                    }
            }.eraseToAnyPublisher()
        }
    }
}
