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

    let blockchainName: String

    init(providers: [PolkadotJsonRpcProvider], network: PolkadotNetwork) {
        self.providers = providers
        self.network = network
        blockchainName = network.blockchainName
    }

    func getInfo(for address: String) -> AnyPublisher<BigUInt, Error> {
        getAccountInfo(address: address)
            .map { accountInfo in
                accountInfo?.data.free ?? 0
            }
            .eraseToAnyPublisher()
    }

    func blockchainMeta(for address: String) -> AnyPublisher<PolkadotBlockchainMeta, Error> {
        makeStorageKeyPublisher(forAddress: address)
            .withWeakCaptureOf(self)
            .flatMap { service, key in
                service.providerPublisher { provider in
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

                    let getNoncePublisher: AnyPublisher<UInt32, Error> = provider.storage(key: key)
                        .tryMap { storage in
                            guard let storage else {
                                return 0
                            }

                            let info = try decode(PolkadotAccountInfo.self, from: Data(hexString: storage))
                            return info.nonce
                        }
                        .eraseToAnyPublisher()

                    return Publishers.Zip4(
                        provider.blockhash(.genesis),
                        latestBlockPublisher,
                        getNoncePublisher,
                        provider.runtimeVersion()
                    ).map { genesisHash, latestBlockInfo, nonce, runtimeVersion in
                        PolkadotBlockchainMeta(
                            specVersion: runtimeVersion.specVersion,
                            transactionVersion: runtimeVersion.transactionVersion,
                            genesisHash: genesisHash,
                            blockHash: latestBlockInfo.0,
                            nonce: nonce,
                            era: .init(blockNumber: latestBlockInfo.1, period: 128) // Should be power of two
                        )
                    }
                    .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
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
}

// MARK: - PolkadotAccountInfo

private extension PolkadotNetworkService {
    private func makeStorageKey(forAddress address: String) throws -> String {
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
        return key.hex().addHexPrefix()
    }

    private func makeStorageKeyPublisher(forAddress address: String) -> AnyPublisher<String, Error> {
        Result { try makeStorageKey(forAddress: address) }
            .publisher
            .eraseToAnyPublisher()
    }

    private func getAccountInfo(address: String) -> AnyPublisher<PolkadotAccountInfo?, Error> {
        makeStorageKeyPublisher(forAddress: address)
            .withWeakCaptureOf(self)
            .flatMap { service, key in
                service.providerPublisher { provider in
                    provider.storage(key: key)
                }
            }
            .tryMap { storage in
                guard let storage else {
                    return nil
                }

                return try decode(PolkadotAccountInfo.self, from: Data(hexString: storage))
            }
            .eraseToAnyPublisher()
    }
}
