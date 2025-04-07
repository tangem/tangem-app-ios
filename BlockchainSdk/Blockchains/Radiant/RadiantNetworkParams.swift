//
//  RadiantNetworkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BitcoinCore

/// https://github.com/RadiantBlockchain/radiant-node/blob/3bfd3ed2ed535b7d3058cbeecc2caa5be8f1115f/src/chainparams.cpp#L193
class RadiantNetworkParams: INetwork {
    let bundleName = "BitcoinKit"

    let pubKeyHash: UInt8 = 0x00 // addressHeader
    let privateKey: UInt8 = 0x80 // dumpedPrivateKeyHeader
    let scriptHash: UInt8 = 0x05 // p2shHeader
    let bech32PrefixPattern: String = "radaddr" // segwitAddressHrp
    let xPubKey: UInt32 = 0x0488b21e // bip32HeaderP2PKHpub
    let xPrivKey: UInt32 = 0x0488ade4 // bip32HeaderP2PKHpriv
    let magic: UInt32 = 0xe3e1f3e8 // packetMagic
    let port: UInt32 = 8333 // port
    let coinType: UInt32 = 145
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true

    let dnsSeeds = [
        "seed.bitcoin.sipa.be", // Pieter Wuille
        "dnsseed.bluematt.me", // Matt Corallo
        "dnsseed.bitcoin.dashjr.org", // Luke Dashjr
        "seed.bitcoinstats.com", // Chris Decker
        "seed.bitnodes.io", // Addy Yeow
        "seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
    ]

    let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
}

extension RadiantNetworkParams: UTXONetworkParams {
    var p2pkhPrefix: UInt8 { pubKeyHash }
    var p2shPrefix: UInt8 { scriptHash }
    var bech32Prefix: String { bech32PrefixPattern }
}
