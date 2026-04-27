//
//  StellarAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import TangemSdk
@testable import BlockchainSdk
import Testing
import enum WalletCore.CoinType

struct StellarAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()

    @Test
    func addressGeneration() {
        let addressService = AddressServiceFactory(blockchain: .stellar(curve: .ed25519, testnet: false)).makeAddressService()
        let walletPubkey = Data(hex: "EC5387D8B38BD9EF80BDBC78D0D7E1C53F08E269436C99D5B3C2DF4B2CE73012")
        let expectedAddress = "GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ"
        #expect(try! addressService.makeAddress(from: walletPubkey).value == expectedAddress)
    }

    @Test(
        arguments: [
            Blockchain.stellar(curve: .ed25519, testnet: false),
            .stellar(curve: .ed25519_slip0010, testnet: false),
        ]
    )
    func xmlEd25519AddressGeneration(blockchain: Blockchain) throws {
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addrs = try service.makeAddress(from: Keys.AddressesKeys.edKey)

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }

        #expect(addrs.localizedName == AddressType.default.defaultLocalizedName)
        #expect(addrs.value == "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.edKey, for: blockchain) == "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")

        let addr = try? AddressServiceManagerUtility().makeTrustWalletAddress(publicKey: Keys.AddressesKeys.edKey, for: blockchain)
        #expect(addrs.value == addr)
    }

    @Test
    func testnetXmlAddressGeneration() throws {
        let service = AddressServiceFactory(blockchain: .stellar(curve: .ed25519, testnet: false)).makeAddressService()
        let addrs = try service.makeAddress(from: Keys.AddressesKeys.edKey)

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }

        #expect(addrs.localizedName == AddressType.default.defaultLocalizedName)
        #expect(addrs.value == "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
    }

    @Test(arguments: [
        "GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ",
        "GAE2SZV4VLGBAPRYRFV2VY7YYLYGYIP5I7OU7BSP6DJT7GAZ35OKFDYI",
        "GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ",
    ])
    func validAddresses(addressHex: String) {
        [EllipticCurve.ed25519, .ed25519_slip0010].forEach {
            let addressValidator = AddressServiceFactory(blockchain: .stellar(curve: $0, testnet: false)).makeAddressService()
            #expect(addressValidator.validate(addressHex))
        }
    }

    @Test(arguments: [
        "GDWFc",
        "GDWFHядыфлвФЫВЗФЫВЛ++EÈ",
    ])
    func invalidAddresses(addressHex: String) {
        [EllipticCurve.ed25519, .ed25519_slip0010].forEach {
            let addressValidator = AddressServiceFactory(blockchain: .stellar(curve: $0, testnet: false)).makeAddressService()
            #expect(!addressValidator.validate(addressHex))
        }
    }

    @Test(arguments: [
        "USDCC-GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ",
        "USDC-GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ",
        "USDC-GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ-1",
        "USDC:GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ-1",
        "USDC:GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ",
        "POL-GAE2SZV4VLGBAPRYRFV2VY7YYLYGYIP5I7OU7BSP6DJT7GAZ35OKFDYI",
        "AA-GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ",
        "A-GDWFHB6YWOF5T34AXW6HRUGX4HCT6CHCNFBWZGOVWPBN6SZM44YBFUDZ"
    ])
    func validCustomTokenAddresses(addressHex: String) {
        [EllipticCurve.ed25519, .ed25519_slip0010].forEach {
            let customTokenValidator = AddressServiceFactory(blockchain: .stellar(curve: $0, testnet: false)).makeAddressService()
            #expect(customTokenValidator.validateCustomTokenAddress(addressHex))
        }
    }

    @Test(arguments: [
        "usdc-GDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHD", // lowercase asset code
        "USDC-GDWFHядыфлвФЫВЗФЫВЛ++EÈ", // invalid issuer characters
        "USDC-", // missing issuer
        "-GDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFHDWFH", // missing asset code
        "USDC:G123", // valid colon but invalid issuer
        "GDUKMGUGDZQK6YH7ZB7UZUQ3Z5VYK3Z4NSY4CIKMFQJZCEBOUJ4CHGDU", // issuer only
        "USDCGDUKMGUGDZQK6YH7ZB7UZUQ3Z5VYK3Z4NSY4CIKMFQJZCEBOUJ4CHGDU", // no separator
        "USDC-GDUKMGUGDZQK6YH7ZB7UZUQ3Z5VYK3Z4NSY4CIKMFQJZCEBOUJ4CHGDUFSDFASF", // Too long
        "USDC-GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ-2",
        "USDC:GAB6EDWGWSRZUYUYCWXAFQFBHE5ZEJPDXCIMVZC3LH2C7IU35FTI2NOQ-2"
    ])
    func invalidCustomTokenAddresses(addressHex: String) {
        [EllipticCurve.ed25519, .ed25519_slip0010].forEach {
            let customTokenValidator: AddressValidator = AddressServiceFactory(blockchain: .stellar(curve: $0, testnet: false)).makeAddressService()
            #expect(!customTokenValidator.validateCustomTokenAddress(addressHex))
        }
    }
}
