//
//  XRPAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
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

    @Test(arguments: [
        "X",
        "XVfvix",
        "",
    ])
    func xAddressWithMalformedPayloadThrows(xAddress: String) {
        #expect(throws: XRPError.self) {
            try XRPAddress(xAddress: xAddress)
        }
    }

    @Test
    func xAddressWithOversizedTagThrows() {
        let rAddress = "rU893viamSnsfP3zjzM2KPxjqZjXSXK6VF"
        let oversizedTag = UInt64(UInt32.max) + 1
        let xAddress = Self.encodeXAddressWithUInt64Tag(rAddress: rAddress, tag: oversizedTag)

        #expect(throws: XRPError.self) {
            try XRPAddress(xAddress: xAddress)
        }
    }

    @Test
    func xAddressWithMaxValidTagSucceeds() throws {
        let rAddress = "rU893viamSnsfP3zjzM2KPxjqZjXSXK6VF"
        let xAddress = XRPAddress.encodeXAddress(rAddress: rAddress, tag: UInt32.max)
        let decoded = try XRPAddress(xAddress: xAddress)

        #expect(decoded.tag == UInt32.max)
        #expect(decoded.rAddress == rAddress)
    }

    /// Encodes an X-Address with a raw UInt64 tag to produce a malformed address for testing.
    private static func encodeXAddressWithUInt64Tag(rAddress: String, tag: UInt64) -> String {
        let accountID = XRPSeedWallet.accountID(for: rAddress)
        let prefix: [UInt8] = [0x05, 0x44] // mainnet
        let flags: [UInt8] = [0x01] // has tag
        var tagValue = tag
        let tagBytes = withUnsafeBytes(of: &tagValue) { [UInt8]($0) }
        let concatenated = prefix + accountID + flags + tagBytes
        let check = [UInt8](Data(concatenated).sha256().sha256().prefix(through: 3))
        let concatenatedCheck: [UInt8] = concatenated + check
        return XRPBase58.getString(from: Data(concatenatedCheck))
    }
}
