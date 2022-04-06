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
        ]
    }()

    private lazy var testnetBlockchains: Set<Blockchain> = {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .binance(testnet: true),
            .stellar(testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true),
            .avalanche(testnet: true),
            .solana(testnet: true),
            .fantom(testnet: true),
           // .polkadot(testnet: true),
        ]
    }()
    
    func predefinedBlockchains(isDemo: Bool) -> [Blockchain] {
        if isDemo {
            return Array(predefinedDemoBalances.keys)
        }
        
        return [.ethereum(testnet: false), .bitcoin(testnet: false)]
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
    
    func loadCurrencies(isTestnet: Bool) -> AnyPublisher<[CurrencyModel], Error> {
        readList(isTestnet: isTestnet)
            .map { list in
                list.tokens.map { .init(with: $0, baseImageURL: list.imageHost) }
            }
            .eraseToAnyPublisher()
    }
    
    private func readList(isTestnet: Bool) -> AnyPublisher<CurrenciesList, Error> {
        Just(isTestnet)
            .receive(on: DispatchQueue.global())
            .tryMap { testnet in
                try JsonUtils.readBundleFile(with: testnet ? Constants.testFilename : Constants.filename,
                                             type: CurrenciesList.self,
                                             shouldAddCompilationCondition: false)
            }
            .eraseToAnyPublisher()
    }
}


fileprivate extension SupportedTokenItems {
    enum Constants {
        static let filename: String = "tokens"
        static let testFilename: String = "testnet_tokens"
    }
}
