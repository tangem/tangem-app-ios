//
//  Fact0rnAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk
import BitcoinCore

struct Fact0rnAddressService {
    private let bitcoinAddressService = BitcoinBech32AddressService(networkParams: Fact0rnMainNetworkParams())
}

// MARK: - AddressProvider

extension Fact0rnAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let address = try bitcoinAddressService.makeAddress(from: compressedKey, type: addressType)
        return PlainAddress(value: address.value, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

extension Fact0rnAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        bitcoinAddressService.validate(address)
    }
}

extension Fact0rnAddressService {
    static func addressToScript(address: String) throws -> Script {
        let converter = SegWitBech32AddressConverter(prefix: Fact0rnMainNetworkParams().bech32PrefixPattern, scriptConverter: ScriptConverter())
        let seg = try converter.convert(address: address)

        return try ScriptBuilder.createOutputScript(for: seg)
    }

    static func addressToScriptHash(address: String) throws -> String {
        let p2pkhScript = try addressToScript(address: address)
        let sha256Hash = p2pkhScript.scriptData.getSha256()
        return Data(sha256Hash.reversed()).hexString
    }
}
