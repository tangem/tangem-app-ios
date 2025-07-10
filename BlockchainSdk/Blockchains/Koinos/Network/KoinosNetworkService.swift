//
//  KoinosNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine

class KoinosNetworkService: MultiNetworkProvider {
    let providers: [KoinosNetworkProvider]
    var currentProviderIndex = 0
    let blockchainName: String = Blockchain.koinos(testnet: false).displayName

    init(providers: [KoinosNetworkProvider]) {
        self.providers = providers
    }

    func getInfo(address: String, koinContractId: String?) -> AnyPublisher<KoinosAccountInfo, Error> {
        providerPublisher { provider in
            // skip reloading if cached
            let koinContractIdPublisher: AnyPublisher<String, Never> = if let koinContractId {
                Just(koinContractId).eraseToAnyPublisher()
            } else {
                provider.getKoinContractId()
                    .map(\.contractId)
                    .replaceError(with: provider.koinosNetworkParams.contractID) // fallback to hardcoded
                    .eraseToAnyPublisher()
            }

            return koinContractIdPublisher
                .flatMap { contractId in
                    Publishers.Zip(
                        provider.getKoinBalance(address: address, koinContractId: contractId)
                            .tryMap(KoinosDTOMapper.convertKoinBalance),
                        provider.getRC(address: address).map(KoinosDTOMapper.convertAccountRC)
                    )
                    .map { balance, mana in
                        KoinosAccountInfo(
                            koinContractId: contractId,
                            koinBalance: balance,
                            mana: mana
                        )
                    }
                }
                .eraseToAnyPublisher()
        }
    }

    func getRCLimit() -> AnyPublisher<BigUInt, Error> {
        providerPublisher { provider in
            provider.getResourceLimits()
                .tryMap(KoinosDTOMapper.convertResourceLimitData)
                .map { limits in
                    Constants.maxDiskStorageLimit * limits.diskStorageCost
                        + Constants.maxNetworkLimit * limits.networkBandwidthCost
                        + Constants.maxComputeLimit * limits.computeBandwidthCost
                }
                .eraseToAnyPublisher()
        }
    }

    func getCurrentNonce(address: String) -> AnyPublisher<KoinosAccountNonce, Error> {
        providerPublisher { provider in
            provider
                .getNonce(address: address)
                .tryMap(KoinosDTOMapper.convertNonce)
                .eraseToAnyPublisher()
        }
    }

    func submitTransaction(transaction: KoinosProtocol.Transaction) -> AnyPublisher<KoinosTransactionEntry, Error> {
        providerPublisher { provider in
            provider
                .submitTransaction(transaction: transaction)
                .map(\.receipt)
                .tryMap(KoinosDTOMapper.convertTransactionEntry)
                .eraseToAnyPublisher()
        }
    }

    func getExistingTransactionIDs(transactionIDs: [String]) -> AnyPublisher<Set<String>, Error> {
        providerPublisher { provider in
            provider
                .getTransactions(transactionIDs: transactionIDs)
                .map { response in
                    guard let transactions = response.transactions else {
                        return []
                    }
                    return transactions.map(\.transaction.id).toSet()
                }
                .eraseToAnyPublisher()
        }
    }
}

private extension KoinosNetworkService {
    /// These constants were calculated for us by the Koinos developers and provided to us in a Telegram chat.
    enum Constants {
        static let maxDiskStorageLimit: BigUInt = 118
        static let maxNetworkLimit: BigUInt = 408
        static let maxComputeLimit: BigUInt = 1_000_000
    }
}
