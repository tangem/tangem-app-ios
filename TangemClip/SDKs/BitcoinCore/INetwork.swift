//
//  INetwork.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public protocol INetwork: class {
    var pubKeyHash: UInt8 { get }
    var privateKey: UInt8 { get }
    var scriptHash: UInt8 { get }
    var bech32PrefixPattern: String { get }
    var xPubKey: UInt32 { get }
    var xPrivKey: UInt32 { get }
    var magic: UInt32 { get }
    var port: UInt32 { get }
    var dnsSeeds: [String] { get }
    var dustRelayTxFee: Int { get }
    var coinType: UInt32 { get }
    var sigHash: BitcoinCoreSigHashType { get }
}

public enum BitcoinNetwork {
    case mainnet
    case testnet
    
    public var networkParams: INetwork {
        switch self {
        case .mainnet:
            return MainNet()
        case .testnet:
            return TestNet()
        }
    }
}

class MainNet: INetwork {
   let pubKeyHash: UInt8 = 0x00
   let privateKey: UInt8 = 0x80
   let scriptHash: UInt8 = 0x05
   let bech32PrefixPattern: String = "bc"
   let xPubKey: UInt32 = 0x0488b21e
   let xPrivKey: UInt32 = 0x0488ade4
   let magic: UInt32 = 0xf9beb4d9
   let port: UInt32 = 8333
   let coinType: UInt32 = 0
   let sigHash: BitcoinCoreSigHashType = .bitcoinAll

   let dnsSeeds = [
       "seed.bitcoin.sipa.be",         // Pieter Wuille
       "dnsseed.bluematt.me",          // Matt Corallo
       "dnsseed.bitcoin.dashjr.org",   // Luke Dashjr
       "seed.bitcoinstats.com",        // Chris Decker
       "seed.bitnodes.io",             // Addy Yeow
       "seed.bitcoin.jonasschnelli.ch",// Jonas Schnelli
   ]

   let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
}

class TestNet: INetwork {
    private static let testNetDiffDate = 1329264000 // February 16th 2012
    let pubKeyHash: UInt8 = 0x6f
    let privateKey: UInt8 = 0xef
    let scriptHash: UInt8 = 0xc4
    let bech32PrefixPattern: String = "tb"
    let xPubKey: UInt32 = 0x043587cf
    let xPrivKey: UInt32 = 0x04358394
    let magic: UInt32 = 0x0b110907
    let port: UInt32 = 18333
    let coinType: UInt32 = 1
    let sigHash: BitcoinCoreSigHashType = .bitcoinAll
    let dnsSeeds = [
        "testnet-seed.bitcoin.petertodd.org",    // Peter Todd
        "testnet-seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
        "testnet-seed.bluematt.me",              // Matt Corallo
        "testnet-seed.bitcoin.schildbach.de",    // Andreas Schildbach
        "bitcoin-testnet.bloqseeds.net",         // Bloq
    ]

    let dustRelayTxFee = 3000 // https://github.com/bitcoin/bitcoin/blob/c536dfbcb00fb15963bf5d507b7017c241718bf6/src/policy/policy.h#L50
}
