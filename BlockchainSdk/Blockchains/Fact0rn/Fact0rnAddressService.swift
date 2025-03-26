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
        let address = try bitcoinAddressService.makeAddress(for: publicKey, with: addressType)
        return address
    }
}

// MARK: - AddressValidator

extension Fact0rnAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        bitcoinAddressService.validate(address)
    }
}

extension Fact0rnAddressService {
    static func addressToScriptHash(address: String) throws -> String {
        let params = Fact0rnMainNetworkParams()
        let converter = SegWitBech32AddressConverter(prefix: params.bech32PrefixPattern, scriptConverter: ScriptConverter())
        let address = try converter.convert(address: address)
        let sha256Hash = address.lockingScript.getSha256()
        return Data(sha256Hash.reversed()).hexString
    }
}
