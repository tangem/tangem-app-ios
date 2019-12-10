//
//  Blockchain.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum Blockchain: String {
    case unknown
    case bitcoin
    case bitcoinTestnet
    case ethereum
    case rootstock
    case cardano
    case ripple
    case binance
    case stellar
    
    public var decimalCount: Int16 {
        switch self {
        case .bitcoin:
            return 8
        case .ethereum, .rootstock:
            return 18
        case .ripple, .cardano:
            return 6
        case .binance:
            return 8
        case .stellar:
            return 7
        default:
            assertionFailure()
            return 0
        }
    }
    
    public static func from(name: String) -> Blockchain {
        if name.contains("btc") || name.contains("bitcoin") {
            return name.contains("test") ? .bitcoinTestnet : .bitcoin
        }
        
        fatalError("unsupported blockchain")
    }
    
    public var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .bitcoin, .ethereum, .rootstock, .binance:
            return .down
        case .cardano:
            return .up
        default:
            return .plain
        }
    }
    
    func makeAddress(from cardPublicKey: Data) -> String {
        switch self {
        case .bitcoin:
            return BitcoinAddressFactory().makeAddress(from: cardPublicKey, testnet: false)
        case .bitcoinTestnet:
            return BitcoinAddressFactory().makeAddress(from: cardPublicKey, testnet: true)
        default:
            fatalError("unsupported blockchain")
        }
    }
    
    func validate(address: String) -> Bool {
        switch self {
        case .bitcoin:
            return BitcoinAddressValidator().validate(address: address, testnet: false)
        case .bitcoinTestnet:
            return BitcoinAddressValidator().validate(address: address, testnet: true)
        default:
            fatalError("unsupported blockchain")
        }
    }
}
