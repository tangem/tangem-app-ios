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
