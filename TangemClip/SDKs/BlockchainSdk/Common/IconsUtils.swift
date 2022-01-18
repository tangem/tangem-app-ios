//
//  IconsUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum IconsUtils {
    private static var baseUrl: String {
        "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains"
    }
    private static var logoSuffix: String { "logo.png" }
    
    public static func getBlockchainIconUrl(_ blockchain: Blockchain) -> URL? {
        guard let blockchainPath = blockchain.getPath else { return nil }
        
        return URL(string: baseUrl)?
            .appendingPathComponent(blockchainPath)
            .appendingPathComponent("info")
            .appendingPathComponent(logoSuffix)
    }
    
    public static func getTokenIconUrl(token: Token) -> URL? {
        guard let blockchainPath = token.blockchain.getPath else { return nil }
        
        let tokenPath = normalizeAssetPath(token)
        return URL(string: baseUrl)?
            .appendingPathComponent(blockchainPath)
            .appendingPathComponent("assets")
            .appendingPathComponent(tokenPath)
            .appendingPathComponent(logoSuffix)
    }
    
    private static func normalizeAssetPath(_ token: Token) -> String {
        let path = token.contractAddress
        
        switch token.blockchain {
        case .ethereum:
            return ethereumAddressToChecksum(path) ?? path
        case .binance:
            return path.uppercased()
        default:
            return path
        }
    }
    
    private static func ethereumAddressToChecksum(_ addr:String) -> String? {
        let address = addr.lowercased().stripHexPrefix()
        guard let hash = address.data(using: .ascii)?.sha3(.keccak256).toHexString().stripHexPrefix() else {return nil}
        var ret = "0x"
        
        for (i,char) in address.enumerated() {
            let startIdx = hash.index(hash.startIndex, offsetBy: i)
            let endIdx = hash.index(hash.startIndex, offsetBy: i+1)
            let hashChar = String(hash[startIdx..<endIdx])
            let c = String(char)
            guard let int = Int(hashChar, radix: 16) else {return nil}
            if (int >= 8) {
                ret += c.uppercased()
            } else {
                ret += c
            }
        }
        return ret
    }
}

fileprivate extension Blockchain {
    var getPath: String? {
        switch self {
        case .bitcoin:
            return "bitcoin"
        case .litecoin:
            return "litecoin"
        case .stellar:
            return "stellar"
        case .ethereum:
            return "ethereum"
        case .bitcoinCash:
            return "bitcoincash"
        case .binance:
            return "binance"
        case .cardano:
            return "cardano"
        case .xrp:
            return "xrp"
        case .tezos:
            return "tezos"
        case .rsk, .ducatus:
            return nil
        case .dogecoin:
            return "doge"
        case .bsc:
            return "smartchain"
        case .polygon:
            return "polygon"
        case .avalanche:
            return "avalanchec"
        }
    }
}
