//
//  Blockchain.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum Blockchain {
    case bitcoin(testnet: Bool)
    case litecoin
    case stellar(testnet: Bool)
    case ethereum(testnet: Bool)
    //    case rootstock
    //    case cardano
    //    case ripple
    //    case binance
    //    case stellar
    
    public var isTestnet: Bool {
        switch self {
        case .bitcoin(let testnet):
            return testnet
        case .litecoin:
            return false
        case .stellar(let testnet):
            return testnet
        case .ethereum(let testnet):
            return testnet
        }
    }
    
    public var decimalCount: Int {
        switch self {
        case .bitcoin, .litecoin:
            return 8
        case .ethereum:/*,  .rootstock*/
            return 18
            //        case .ripple, .cardano:
            //            return 6
            //        case .binance:
        //            return 8
        case .stellar:
            return 7
        }
    }
    
    public var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .bitcoin, .litecoin, .ethereum://.rootstock, .binance:
            return .down
        case .stellar:
            return .plain
            //        case .cardano:
            //            return .up
        }
    }
    public var currencySymbol: String {
        switch self {
        case .bitcoin:
            return "BTC"
        case .litecoin:
            return "LTC"
        case .stellar:
            return "XLM"
        case .ethereum:
            return "ETH"
        }
    }
    
    func makeAddress(from walletPublicKey: Data) -> String {
        switch self {
        case .bitcoin(let testnet):
            return BitcoinAddressFactory().makeAddress(from: walletPublicKey, testnet: testnet)
        case .litecoin:
            return LitecoinAddressFactory().makeAddress(from: walletPublicKey, testnet: false)
        case .stellar:
            return StellarAddressFactory().makeAddress(from: walletPublicKey)
        case .ethereum:
            return EthereumAddressFactory().makeAddress(from: walletPublicKey)
        }
    }
    
    func validate(address: String) -> Bool {
        switch self {
        case .bitcoin(let testnet):
            return BitcoinAddressValidator().validate(address, testnet: testnet)
        case .litecoin:
            return LitecoinAddressValidator().validate(address, testnet: false)
        case .stellar:
            return StellarAddressValidator().validate(address)
        case .ethereum:
            return EthereumAddressValidator().validate(address)
        }
    }
}
