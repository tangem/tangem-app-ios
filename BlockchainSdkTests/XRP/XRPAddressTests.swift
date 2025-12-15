//
//  XRPAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
@testable import BlockchainSdk
import Testing
import enum WalletCore.CoinType

struct XRPAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()

    @Test
    func xrpSecpAddressGeneration() throws {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        #expect(service.validate(addr_dec.value))
        #expect(service.validate(addr_comp.value))

        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.value == "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ")

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpDecompressedKey, for: blockchain) == addr_dec.value)

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: [EllipticCurve.ed25519, .ed25519_slip0010])
    func xrpEdAddressGeneration(curve: EllipticCurve) throws {
        let blockchain = Blockchain.xrp(curve: curve)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        let address = try service.makeAddress(from: Keys.AddressesKeys.edKey)

        #expect(service.validate(address.value))

        #expect(address.localizedName == AddressType.default.defaultLocalizedName)
        #expect(address.value == "rPhmKhkYoMiqC2xqHYhtPLnicWQi85uDf2") // [REDACTED_TODO_COMMENT]

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test(arguments: [
        "rDpysuumkweqeC7XdNgYNtzL5GxbdsmrtF",
        "XVfvixWZQKkcenFRYApCjpTUyJ4BePTe3jJv7beatUZvQYh",
        "XVfvixWZQKkcenFRYApCjpTUyJ4BePTe3jJv7beatUZvQYh",
        "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ",
        "r36yxStAh7qgTQNHTzjZvXybCTzUFhrfav",
        "XVfvixWZQKkcenFRYApCjpTUyJ4BePMjMaPqnob9QVPiVJV",
        "rfxdLwsZnoespnTDDb1Xhvbc8EFNdztaoq",
        "rU893viamSnsfP3zjzM2KPxjqZjXSXK6VF",
    ])
    func validAddresses(addressHex: String) {
        [EllipticCurve.ed25519, .ed25519_slip0010].forEach {
            let addressValidator = AddressServiceFactory(blockchain: .xrp(curve: $0)).makeAddressService()
            #expect(addressValidator.validate(addressHex))
        }
    }

    /// https://xrpaddress.info
    @Test(arguments: [
        "XVfvixWZQKkcenFRYApCjpTUyJ4BePTe3jJv7beatUZvQYh",
        "rU893viamSnsfP3zjzM2KPxjqZjXSXK6VF"
    ])
    func xrpAddressCompoundCheck(address: String) {
        let selfAddress = "rU893viamSnsfP3zjzM2KPxjqZjXSXK6VF"

        [EllipticCurve.ed25519, .ed25519_slip0010].forEach {
            let addressValidator = AddressServiceFactory(blockchain: .xrp(curve: $0)).makeAddressService()
            let resolved = addressValidator.resolveAddress(address)
            #expect(resolved == selfAddress)
        }
    }
}
