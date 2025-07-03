//
//  PolkadotNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import ScaleCodec
import Sodium
import BigInt

class PolkadotNetworkService: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    let providers: [PolkadotJsonRpcProvider]

    private let network: PolkadotNetwork

    init(providers: [PolkadotJsonRpcProvider], network: PolkadotNetwork) {
        self.providers = providers
        self.network = network
    }

    func getInfo(for address: String) -> AnyPublisher<BigUInt, Error> {
        providerPublisher { [weak self] provider in
            guard let self else {
                return .emptyFail
            }

            return Result { try self.storageKey(forAddress: address) }
                .publisher
                .flatMap { key -> AnyPublisher<String?, Error> in
                    provider.storage(key: key.hex().addHexPrefix())
                }
                .tryMap { storage in
                    if let storage {
                        let info = try decode(PolkadotAccountInfo.self, from: Data(hexString: storage))
                        return info.data.free
                    }

                    return 0
                }
                .eraseToAnyPublisher()
        }
    }

    func blockchainMeta(for address: String) -> AnyPublisher<PolkadotBlockchainMeta, Error> {
        providerPublisher { provider in
            let latestBlockPublisher: AnyPublisher<(String, UInt64), Error> = provider.blockhash(.latest)
                .flatMap { [weak self] latestBlockHash -> AnyPublisher<(String, UInt64), Error> in
                    guard
                        let self = self,
                        let provider = self.provider
                    else {
                        return .emptyFail
                    }

                    let latestBlockHashPublisher = Just(latestBlockHash).setFailureType(to: Error.self)
                    let latestBlockNumberPublisher = provider
                        .header(latestBlockHash)
                        .map(\.number)
                        .tryMap { UInt64($0.removeHexPrefix(), radix: 16) ?? 0 } // [REDACTED_TODO_COMMENT]

                    return Publishers.Zip(latestBlockHashPublisher, latestBlockNumberPublisher).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()

            return Publishers.Zip4(
                provider.blockhash(.genesis),
                latestBlockPublisher,
                provider.accountNextIndex(address),
                provider.runtimeVersion()
            ).map { genesisHash, latestBlockInfo, nextIndex, runtimeVersion in
                PolkadotBlockchainMeta(
                    specVersion: runtimeVersion.specVersion,
                    transactionVersion: runtimeVersion.transactionVersion,
                    genesisHash: genesisHash,
                    blockHash: latestBlockInfo.0,
                    nonce: nextIndex,
                    era: .init(blockNumber: latestBlockInfo.1, period: 128) // Should be power of two
                )
            }
            .eraseToAnyPublisher()
        }
    }

    func fee(for extrinsic: Data) -> AnyPublisher<PolkadotQueriedInfo, Error> {
        providerPublisher { provider in
            // Payload length param is redundant, but required
            // https://forum.polkadot.network/t/new-json-rpc-api-mega-q-a/3048/2#how-do-i-get-the-metadata-the-account-nonce-or-the-payment-fees-with-the-new-api-6
            let payload = extrinsic + extrinsic.count.bytes4LE
            return provider
                .queryInfo(payload.hex().addHexPrefix())
                .tryMap { output in
                    try decode(PolkadotQueriedInfo.self, from: Data(hexString: output))
                }
                .eraseToAnyPublisher()
        }
    }

    func submitExtrinsic(data: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.submitExtrinsic(data.hex().addHexPrefix())
        }
    }

    private func storageKey(forAddress address: String) throws -> Data {
        guard
            let address = PolkadotAddress(string: address, network: network),
            let addressBytes = address.bytes(raw: true),
            // [REDACTED_TODO_COMMENT]
            let addressHash = Sodium().genericHash.hash(message: addressBytes.bytes, outputLength: 16)
        else {
            throw BlockchainSdkError.empty
        }

        // XXHash of "System" module and "Account" storage item.
        let moduleNameHash = Data(hexString: "26aa394eea5630e07c48ae0c9558cef7")
        let storageNameKeyHash = Data(hexString: "b99d880ec681799c0cf30e8886371da9")

        let key = moduleNameHash + storageNameKeyHash + addressHash + addressBytes
        return key
    }
}
