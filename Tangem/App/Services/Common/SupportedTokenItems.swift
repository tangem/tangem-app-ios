//
//  SupportedTokenItems.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token
import enum BlockchainSdk.Blockchain
import TangemSdk
import Combine

class SupportedTokenItems {
    lazy var predefinedDemoBalances: [Blockchain: Decimal] = {
        [
            .bitcoin(testnet: false): 0.005,
            .ethereum(testnet: false): 0.12,
            .dogecoin: 45,
            .solana(testnet: false): 3.246,
        ]
    }()

    private lazy var blockchains: Set<Blockchain> = {
        [
            .ethereum(testnet: false),
            .ethereumClassic(testnet: false),
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash(testnet: false),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: .secp256k1),
            .stellar(testnet: false),
            .cardano(shelley: true),
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false),
            .solana(testnet: false),
//            .polkadot(testnet: false),
//            .kusama,
            .fantom(testnet: false),
            .tron(testnet: false),
            .arbitrum(testnet: false),
            .gnosis,
        ]
    }()

    private lazy var testnetBlockchains: Set<Blockchain> = {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .ethereumClassic(testnet: true),
            .binance(testnet: true),
            .stellar(testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true),
            .avalanche(testnet: true),
            .solana(testnet: true),
            .fantom(testnet: true),
            // .polkadot(testnet: true),
            .tron(testnet: true),
            .arbitrum(testnet: true),
        ]
    }()

    func predefinedBlockchains(isDemo: Bool, testnet: Bool) -> [Blockchain] {
        if isDemo {
            return Array(predefinedDemoBalances.keys)
        }

        return [.ethereum(testnet: testnet), .bitcoin(testnet: testnet)]
    }

    func blockchains(for curves: [EllipticCurve], isTestnet: Bool?) -> Set<Blockchain> {
        let allBlockchains = isTestnet.map { $0 ? testnetBlockchains : blockchains }
            ?? testnetBlockchains.union(blockchains)
        return allBlockchains.filter { curves.contains($0.curve) }
    }

    func blockchainsWithTokens(isTestnet: Bool) -> Set<Blockchain> {
        let blockchains = isTestnet ? testnetBlockchains : blockchains
        return blockchains.filter { $0.canHandleTokens }
    }

    func evmBlockchains(isTestnet: Bool) -> Set<Blockchain> {
        let blockchains = isTestnet ? testnetBlockchains : blockchains
        return blockchains.filter { $0.isEvm }
    }

    func loadTestnetCoins(supportedCurves: [EllipticCurve]) -> AnyPublisher<[CoinModel], Error> {
        readTestnetList()
            .map { list in
                list.coins.compactMap {
                    CoinModel(with: $0, baseImageURL: list.imageHost)
                        .withFiltered(supportedCurves: supportedCurves)
                }
            }
            .eraseToAnyPublisher()
    }

    private func readTestnetList() -> AnyPublisher<CoinsResponse, Error> {
        Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { testnet in
                try JsonUtils.readBundleFile(with: Constants.testFilename,
                                             type: CoinsResponse.self,
                                             shouldAddCompilationCondition: false)
            }
            .eraseToAnyPublisher()
    }
}


fileprivate extension SupportedTokenItems {
    enum Constants {
        static let testFilename: String = "testnet_tokens"
    }
}

private extension CoinModel {
    /// Filter the `tokenItems` for supportedCurves. Used only for testnet coinds from a local file
    func withFiltered(supportedCurves: [EllipticCurve]) -> CoinModel? {
        let filteredItems = items.filter { item in
            supportedCurves.contains(item.blockchain.curve)
        }

        if filteredItems.isEmpty {
            return nil
        }

        return makeCopy(with: filteredItems)
    }

    private func makeCopy(with items: [TokenItem]) -> CoinModel {
        CoinModel(id: id, name: name, symbol: symbol, imageURL: imageURL, items: items)
    }
}
