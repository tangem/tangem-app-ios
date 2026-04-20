//
//  HederaAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoKit
import Testing
import class WalletCore.PrivateKey
@testable import BlockchainSdk

struct HederaAddressTests {
    @Test
    func testHederaEd25519() throws {
        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try #require(PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .ed25519, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    @Test
    func testHederaEd25519Slip0010() throws {
        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try #require(PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .ed25519, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    @Test
    func testHederaSecp256k1() throws {
        // ECDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x3030020100300706052b8104000a04220420e507077d8d5bab32debcbbc651fc4ca74660523976502beabee15a1662d77ed1")

        // Hedera ECDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/f65ab2a4cf5bb026fc47fcf8955e81c2b82a6ff3/packages/cryptography/src/EcdsaPrivateKey.js#L7
        let hederaDerPrefixPrivate = Data(hexString: "0x3030020100300706052b8104000a04220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try #require(PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .secp256k1, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    func testHederaAddressGeneration(blockchain: Blockchain, privateKey: WalletCore.PrivateKey) throws {
        let publicKeyRaw = privateKey.getPublicKeyByType(pubkeyType: try .init(blockchain)).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyRaw, derivationType: nil)

        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        // Both ECDSA and EdDSA are supported
        _ = try addressService.makeAddress(for: publicKey, with: .default)
        _ = try addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        _ = try addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        _ = try addressService.makeAddress(from: Keys.AddressesKeys.edKey)

        // Actual address (i.e. Account ID) for Hedera is requested asynchronously from the network/local storage,
        // therefore the address service returns an empty string, this is perfectly fine
        let expectedAddress = ""
        let address = try addressService.makeAddress(for: publicKey, with: .default)

        #expect(AddressType.default.defaultLocalizedName == address.localizedName)
        #expect(expectedAddress == address.value)
    }

    /// Includes account IDs with checksums from https://hips.hedera.com/hip/hip-15
    func testHederaAddressValidation(blockchain: Blockchain) throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        #expect(addressService.validate("0.0.123"))
        #expect(addressService.validate("0.0.123-vfmkw"))
        #expect(addressService.validate("0.0.1234567890-zbhlt"))
        #expect(addressService.validate("0.0.9223372036854775807")) // Account number part fits Int64
        #expect(!addressService.validate("0.0.18446744073709551615")) // Account number part exceeds Int64
        #expect(addressService.validate("0x000000000000000000000000000000000087da23")) // Hedera supports EVM addresses (but only hedera-compatible)
        #expect(!addressService.validate("0xf3DbcEeedDC4BBd1B66492B66EC0B8eC317b511B"))

        #expect(addressService.validate("0.0.302d300706052b8104000a03220002d588ec1000770949ab77516c77ee729774de1c8fe058cab6d64f1b12ffc8ff07")) // Account Alias

        #expect(!addressService.validate("0.0.123-abcde"))
        #expect(!addressService.validate("0.0.123-VFMKW"))
        #expect(!addressService.validate("0.0.123-vFmKw"))
        #expect(!addressService.validate("0.0.123#vfmkw"))
        #expect(!addressService.validate("0.0.123vfmkw"))
        #expect(!addressService.validate("0.0.123 - vfmkw"))
        #expect(!addressService.validate("0.123"))
        #expect(!addressService.validate("0.0.123."))
        #expect(!addressService.validate("0.0.123-vf"))
        #expect(!addressService.validate("0.0.123-vfm-kw"))
        #expect(!addressService.validate("0.0.123-vfmkwxxxx"))
        #expect(!addressService.validate("0.0.18446744073709551616")) // Max length of the account number part is 8 bytes (2^64 - 1)
        #expect(!addressService.validate("0xf64a1db2f124aaa4cd7b58d3d7f66774f9770c6")) // Hedera supports EVM addresses
        #expect(!addressService.validate("0xf64a1db2f124aaa4cd7b58d3d7f66774f9770c6ee")) // Hedera supports EVM addresses
        #expect(!addressService.validate("0.0.402d300706052b8104000a03220002d588ec1000770949ab77516c77ee729774de1c8fe058cab6d64f1b12ffc8ff07")) // Account Alias
        #expect(!addressService.validate(""))
    }
}
