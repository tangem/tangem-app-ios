//
//  AlephiumNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

class AlephiumNetworkService: MultiNetworkProvider {
    // MARK: - Protperties

    let providers: [AlephiumNetworkProvider]
    var currentProviderIndex: Int = 0

    // MARK: - Init

    init(providers: [AlephiumNetworkProvider]) {
        self.providers = providers
    }

    // MARK: - Implementation

    func getAccountInfo(for address: String) -> AnyPublisher<AlephiumAccountInfo, Error> {
        getUTXO(address: address)
            .tryMap {
                AlephiumAccountInfo(utxo: $0)
            }
            .eraseToAnyPublisher()
    }

    func getFee(
        from publicKey: String,
        destination: String,
        amount: BigUInt
    ) -> AnyPublisher<Decimal, Error> {
        let destination = AlephiumNetworkRequest.Destination(
            address: destination,
            attoAlphAmount: amount.description
        )

        let transfer = AlephiumNetworkRequest.BuildTransferTx(
            fromPublicKey: publicKey,
            destinations: [destination]
        )

        return providerPublisher { provider in
            provider
                .buildTransaction(transfer: transfer)
                .tryMap { response in
                    let gasPriceValue = Decimal(stringValue: response.gasPrice) ?? ALPH.Constants.nonCoinbaseMinValue
                    return gasPriceValue
                }
                .eraseToAnyPublisher()
        }
    }

    func submitTx(unsignedTx: String, signature: String) -> AnyPublisher<String, Error> {
        let submit = AlephiumNetworkRequest.Submit(unsignedTx: unsignedTx, signature: signature)

        return providerPublisher { provider in
            provider
                .submit(transaction: submit)
                .map { $0.txId }
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Private Implementations

    private func getBalance(address: String) -> AnyPublisher<AlephiumBalanceInfo, Error> {
        providerPublisher { provider in
            provider
                .getBalance(address: address)
                .tryMap {
                    guard
                        let balance = Decimal(stringValue: $0.balance),
                        let lockedBalance = Decimal(stringValue: $0.lockedBalance)
                    else {
                        throw WalletError.empty
                    }

                    return AlephiumBalanceInfo(value: balance, lockedValue: lockedBalance)
                }
                .eraseToAnyPublisher()
        }
    }

    private func getUTXO(address: String) -> AnyPublisher<[AlephiumUTXO], Error> {
        providerPublisher { provider in
            provider
                .getUTXOs(address: address)
                .map { result in
                    let utxo: [AlephiumUTXO] = result.utxos.compactMap {
                        guard let amountValue = Decimal(stringValue: $0.amount) else {
                            return nil
                        }

                        return AlephiumUTXO(
                            hint: $0.ref.hint,
                            key: $0.ref.key,
                            value: amountValue,
                            lockTime: $0.lockTime,
                            additionalData: $0.additionalData
                        )
                    }

                    return utxo
                }
                .eraseToAnyPublisher()
        }
    }
}
