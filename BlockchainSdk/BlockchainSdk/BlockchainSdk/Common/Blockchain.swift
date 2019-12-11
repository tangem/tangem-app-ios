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
    //    case ethereum
    //    case rootstock
    //    case cardano
    //    case ripple
    //    case binance
    //    case stellar
    
    public var decimalCount: Int16 {
        switch self {
        case .bitcoin, .bitcoinTestnet:
            return 8
            //        case .ethereum, .rootstock:
            //            return 18
            //        case .ripple, .cardano:
            //            return 6
            //        case .binance:
            //            return 8
            //        case .stellar:
        //            return 7
        case .unknown:
            assertionFailure()
            return 0
        }
    }
    
    public var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .bitcoin, .bitcoinTestnet://, .ethereum, .rootstock, .binance:
            return .down
            //        case .cardano:
        //            return .up
        case .unknown:
            assertionFailure()
            return .plain
        }
    }
    
    func makeAddress(from cardPublicKey: Data) -> String {
        switch self {
        case .bitcoin:
            return BitcoinAddressFactory().makeAddress(from: cardPublicKey, testnet: false)
        case .bitcoinTestnet:
            return BitcoinAddressFactory().makeAddress(from: cardPublicKey, testnet: true)
        case .unknown:
            assertionFailure()
            return ""
        }
    }
    
    func validate(address: String) -> Bool {
        switch self {
        case .bitcoin:
            return BitcoinAddressValidator().validate(address: address, testnet: false)
        case .bitcoinTestnet:
            return BitcoinAddressValidator().validate(address: address, testnet: true)
        case .unknown:
            assertionFailure()
            return false
        }
    }
}
