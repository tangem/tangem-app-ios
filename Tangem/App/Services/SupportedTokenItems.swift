//
//  SupportedTokenItems.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
#if !CLIP
import struct BlockchainSdk.Token
import enum BlockchainSdk.Blockchain
#endif
import TangemSdk

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

    func tokens(for blockchain: Blockchain) -> [Token] {
        do {
            let currencies = try loadCurrencies(isTestnet: blockchain.isTestnet)
            return currencies.compactMap {
                $0.items.compactMap({ $0.token }).first(where: { $0.blockchain == blockchain })
            }
        } catch {
            Log.error(error.localizedDescription)
            return []
        }
    }
    
    func loadCurrencies(isTestnet: Bool) throws -> [CurrencyModel] {
        let list = try readList(isTestnet: isTestnet)
        return list.tokens.map { .init(with: $0, baseImageURL: list.imageHost) }
    }

    
    private func readList(isTestnet: Bool) throws -> CurrenciesList {
        try JsonUtils.readBundleFile(with: isTestnet ? Constants.testFilename : Constants.filename,
                                     type: CurrenciesList.self,
                                     shouldAddCompilationCondition: false)
    }
}


fileprivate extension SupportedTokenItems {
    enum Constants {
        static let filename: String = "tokens"
        static let testFilename: String = "testnet_tokens"
    }
}
