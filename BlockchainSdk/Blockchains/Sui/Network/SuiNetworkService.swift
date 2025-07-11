//
// SuiNetworkService.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore

final class SuiNetworkService: MultiNetworkProvider {
    let providers: [SuiNetworkProvider]
    let balanceFetcher = SuiBalanceFetcher()
    let blockchainName: String = Blockchain.sui(curve: .ed25519_slip0010, testnet: false).displayName
    var currentProviderIndex: Int

    init(providers: [SuiNetworkProvider]) {
        self.providers = providers
        currentProviderIndex = 0
    }

    func getBalance(address: String, coinType: SuiCoinObject.CoinType, cursor: String?) -> AnyPublisher<Result<[SuiGetCoins.Coin], Error>, Never> {
        return balanceFetcher
            .setupRequestPublisherBuilder { [weak self] nextAddress, nextCoin, nextCursor in
                guard let self else {
                    return .anyFail(error: BlockchainSdkError.networkUnavailable)
                }
                return providerPublisher { provider in
                    provider
                        .getBalance(address: nextAddress, coin: nextCoin, cursor: nextCursor)
                }
            }
            .fetchBalance(address: address, coin: coinType.string, cursor: cursor)
    }

    func getReferenceGasPrice() -> AnyPublisher<SuiReferenceGasPrice, Error> {
        return providerPublisher { provider in
            provider
                .getReferenceGasPrice()
        }
    }

    func dryTransaction(transaction raw: String) -> AnyPublisher<SuiInspectTransaction, Error> {
        return providerPublisher { provider in
            provider
                .dryRunTransaction(transaction: raw)
        }
    }

    func sendTransaction(transaction raw: String, signature: String) -> AnyPublisher<SuiExecuteTransaction, Error> {
        return providerPublisher { provider in
            provider
                .sendTransaction(transaction: raw, signature: signature)
        }
    }
}
