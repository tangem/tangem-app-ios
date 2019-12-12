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
    case bitcoin
    case bitcoinTestnet
    case stellar
    case stellarTestnet
    //    case ethereum
    //    case rootstock
    //    case cardano
    //    case ripple
    //    case binance
    //    case stellar
    
    public var decimalCount: Int {
        switch self {
        case .bitcoin, .bitcoinTestnet:
            return 8
            //        case .ethereum, .rootstock:
            //            return 18
            //        case .ripple, .cardano:
            //            return 6
            //        case .binance:
        //            return 8
        case .stellar, .stellarTestnet:
            return 7
        }
    }
    
    public var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .bitcoin, .bitcoinTestnet://, .ethereum, .rootstock, .binance:
            return .down
        case .stellar, .stellarTestnet:
            return .plain
            //        case .cardano:
        //            return .up
        }
    }
    public var currencySymbol: String {
        switch self {
        case .bitcoin, .bitcoinTestnet:
            return "BTC"
        case .stellar, .stellarTestnet:
            return "XLM"
        }
    }
    
    func makeAddress(from walletPublicKey: Data) -> String {
        switch self {
        case .bitcoin:
            return BitcoinAddressFactory().makeAddress(from: walletPublicKey, testnet: false)
        case .bitcoinTestnet:
            return BitcoinAddressFactory().makeAddress(from: walletPublicKey, testnet: true)
        case .stellar, .stellarTestnet:
            return StellarAddressFactory().makeAddress(from: walletPublicKey)
        }
    }
    
    func validate(address: String) -> Bool {
        switch self {
        case .bitcoin:
            return BitcoinAddressValidator().validate(address, testnet: false)
        case .bitcoinTestnet:
            return BitcoinAddressValidator().validate(address, testnet: true)
        case .stellar, .stellarTestnet:
            return StellarAddressValidator().validate(address)
        }
    }
}
