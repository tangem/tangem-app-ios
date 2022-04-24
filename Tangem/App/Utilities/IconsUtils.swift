//
//  IconsUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public enum IconsUtils {
    private static var baseUrl: String {
        "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains"
    }
    private static var logoSuffix: String { "logo.png" }
    
    public static func getBlockchainIcon(_ blockchain: Blockchain) -> String? {
        switch blockchain {
        case .binance, .litecoin, .cardano, .bitcoin,
                .bitcoinCash, .ethereum, .rsk, .tezos, .xrp, .stellar:
            return "\(blockchain.codingKey)".lowercased()
        default:
            return nil
        }
    }
   
    public static func getBlockchainIconUrl(_ blockchain: Blockchain) -> URL? {
        guard let blockchainPath = blockchain.getPath else { return nil }
        
        return URL(string: baseUrl)?
            .appendingPathComponent(blockchainPath)
            .appendingPathComponent("info")
            .appendingPathComponent(logoSuffix)
    }
}

fileprivate extension Blockchain {
    var getPath: String? { //from https://github.com/trustwallet/assets/tree/master/blockchains
        switch self {
        case .rsk, .ducatus:
            return nil
        case .bsc:
            return "smartchain"
        case .avalanche:
            return "avalanchec"
        case .dogecoin:
            return "doge"
        default:
            return "\(codingKey)".lowercased()
        }
    }
}
