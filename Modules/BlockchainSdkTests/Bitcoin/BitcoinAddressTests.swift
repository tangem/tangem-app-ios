//
//  BitcoinAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoKit
import WalletCore
import Testing
@testable import BlockchainSdk

struct BitcoinAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()
    private let blockchain = Blockchain.bitcoin(testnet: false)

    @Test
    func defaultAddressGeneration() throws {
        // given
        let blockchain = Blockchain.bitcoin(testnet: false)
        let service = BitcoinAddressService(networkParams: BitcoinNetworkParams())

        // when
        let bech32_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .default)

        let leg_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .legacy)

        // then
        #expect(bech32_dec.value == bech32_comp.value)
        #expect(bech32_dec.value == "bc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5edc40am")
        #expect(bech32_dec.localizedName == bech32_comp.localizedName)

        try #expect(
            addressesUtility.makeTrustWalletAddress(
                publicKey: Keys.AddressesKeys.secpDecompressedKey,
                for: blockchain
            ) == bech32_dec.value
        )

        #expect(leg_dec.localizedName == leg_comp.localizedName)
        #expect(leg_dec.value == "1HTBz4DRWpDET1QNMqsWKJ39WyWcwPWexK")
        #expect(leg_comp.value == "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")
    }

    @Test
    func defaultAddressGeneration2() throws {
        let walletPublicKey = Data(hex: "046DB397495FA03FE263EE4021B77C49496E5C7DB8266E6E33A03D5B3A370C3D6D744A863B14DE2457D82BEE322416523E336530760C4533AEE980F4A4CDB9A98D")
        let expectedLegacyAddress = "1KWFv7SBZGMsneK2ZJ3D4aKcCzbvEyUbAA"
        let expectedSegwitAddress = "bc1qxzdqcmh6pknevm2ugtw94y50dwhsu3l0p5tg63"

        let addressService = BitcoinAddressService(networkParams: BitcoinNetworkParams())
        let legacy = try addressService.makeAddress(from: walletPublicKey, type: .legacy)
        #expect(legacy.value == expectedLegacyAddress)

        let segwit = try addressService.makeAddress(from: walletPublicKey, type: .default)
        #expect(segwit.value == expectedSegwitAddress)
    }

    @Test
    func legacyAddressGeneration() throws {
        let btcAddress = "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs"
        let publicKey = Data(hex: "0250863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b2352")
        let service = BitcoinLegacyAddressService(networkParams: BitcoinNetworkParams())
        #expect(try service.makeAddress(from: publicKey).value == btcAddress)
    }

    @Test
    func testnetAddressGeneration() throws {
        // given
        let service = BitcoinAddressService(networkParams: BitcoinTestnetNetworkParams())

        // when
        let bech32_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .default)

        let leg_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey, type: .legacy)

        // then
        #expect(bech32_dec.value == bech32_comp.value)
        #expect(bech32_dec.localizedName == bech32_comp.localizedName)
        #expect(bech32_dec.value == "tb1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5e87wuxg") // [REDACTED_TODO_COMMENT]

        #expect(leg_dec.localizedName == leg_comp.localizedName)
        #expect(leg_dec.value == "mwy9H7JQKqeVE7sz5Qqt9DFUNy7KtX7wHj") // [REDACTED_TODO_COMMENT]
        #expect(leg_comp.value == "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") // [REDACTED_TODO_COMMENT]
    }

    @Test
    func invalidCurveGeneration_throwsError() throws {
        let service = BitcoinAddressService(networkParams: BitcoinNetworkParams())
        let testnetService = BitcoinAddressService(networkParams: BitcoinTestnetNetworkParams())

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }

        #expect(throws: (any Error).self) {
            try testnetService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test
    func multisigAddressGeneration() throws {
        // given
        let walletPublicKey1 = Data(hex: "04752A727E14BBA5BD73B6714D72500F61FFD11026AD1196D2E1C54577CBEEAC3D11FC68A64700F8D533F4E311964EA8FB3AA26C588295F2133868D69C3E628693")
        let walletPublicKey2 = Data(hex: "04E3F3BE3CE3D8284DB3BA073AD0291040093D83C11A277B905D5555C9EC41073E103F4D9D299EDEA8285C51C3356A8681A545618C174251B984DF841F49D2376F")
        let numberOfAddresses = 2
        let expectedLegacyAddress = "358vzrRZUDZ8DM5Zbz9oLqGr8voPYQqe56"
        let expectedSegwitAddress = "bc1qw9czf0m0eu0v5uhdqj9l4w9su3ca0pegzxxk947hrehma343qwusy4nf8c"
        let service = BitcoinAddressService(networkParams: BitcoinNetworkParams())

        // when
        let addresses = try service.makeAddresses(publicKey: .init(seedKey: walletPublicKey1, derivationType: .none), pairPublicKey: walletPublicKey2)
        let reversedPubkeysAddresses = try service.makeAddresses(publicKey: .init(seedKey: walletPublicKey2, derivationType: .none), pairPublicKey: walletPublicKey1)

        var legacy: BlockchainSdk.Address?
        var segwit: BlockchainSdk.Address?
        zip(addresses, reversedPubkeysAddresses).forEach {
            #expect($0.value == $1.value)
            if $0.type == .legacy {
                legacy = $0
            }
            if $0.type == .default {
                segwit = $0
            }
        }

        // then
        #expect(addresses != nil)
        #expect(addresses.count == numberOfAddresses)
        #expect(reversedPubkeysAddresses != nil)
        #expect(reversedPubkeysAddresses.count == numberOfAddresses)

        #expect(legacy?.value == expectedLegacyAddress)
        #expect(segwit?.value == expectedSegwitAddress)
    }

    @Test
    func btcTwinAddressGeneration() throws {
        // given
        let secpPairDecompressedKey = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        let secpPairCompressedKey = Data(hexString: "022A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D89")
        let service = BitcoinAddressService(networkParams: BitcoinNetworkParams())

        // when
        let addr_dec = try service.makeAddresses(
            publicKey: .init(seedKey: Keys.AddressesKeys.secpDecompressedKey, derivationType: .none),
            pairPublicKey: secpPairDecompressedKey
        )
        let addr_dec1 = try service.makeAddresses(
            publicKey: .init(seedKey: Keys.AddressesKeys.secpDecompressedKey, derivationType: .none),
            pairPublicKey: secpPairCompressedKey
        )
        let addr_comp = try service.makeAddresses(
            publicKey: .init(seedKey: Keys.AddressesKeys.secpCompressedKey, derivationType: .none),
            pairPublicKey: secpPairCompressedKey
        )
        let addr_comp1 = try service.makeAddresses(
            publicKey: .init(seedKey: Keys.AddressesKeys.secpCompressedKey, derivationType: .none),
            pairPublicKey: secpPairDecompressedKey
        )

        // then
        #expect(addr_dec.count == 2)
        #expect(addr_dec1.count == 2)
        #expect(addr_comp.count == 2)
        #expect(addr_comp1.count == 2)

        #expect(addr_dec.first(where: { $0.type == .default })!.value == "bc1q0u3heda6uhq7fulsqmw40heuh3e76nd9skxngv93uzz3z6xtpjmsrh88wh")
        #expect(addr_dec.first(where: { $0.type == .legacy })!.value == "34DmpSKfsvqxgzVVhcEepeX3s67ai4ShPq")

        for index in 0 ..< 2 {
            #expect(addr_dec[index].value == addr_dec1[index].value)
            #expect(addr_dec[index].value == addr_comp[index].value)
            #expect(addr_dec[index].value == addr_comp1[index].value)

            #expect(addr_dec[index].localizedName == addr_dec1[index].localizedName)
            #expect(addr_dec[index].localizedName == addr_comp[index].localizedName)
            #expect(addr_dec[index].localizedName == addr_comp1[index].localizedName)

            #expect(addr_dec[index].type == addr_dec1[index].type)
            #expect(addr_dec[index].type == addr_comp[index].type)
            #expect(addr_dec[index].type == addr_comp1[index].type)
        }
    }

    @Test(arguments: [
        "bc1q2ddhp55sq2l4xnqhpdv0xazg02v9dr7uu8c2p2",
        "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
        "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2",
        "1AC4gh14wwZPULVPCdxUkgqbtPvC92PQPN",
        "1PMycacnJaSqwwJqjawXBErnLsZ7RkXUAs",
        "bc1qcj2vfjec3c3luf9fx9vddnglhh9gawmncmgxhz",
        "bc1qxzdqcmh6pknevm2ugtw94y50dwhsu3l0p5tg63",
        "bc1pyzns9j3llzxar0dd50nrus6p0cdqjxxqz6y33cmml3qsedlejsyq867kcg",
        "1KWFv7SBZGMsneK2ZJ3D4aKcCzbvEyUbAA",
    ])
    func addressValidation_validAddresses(addressHex: String) {
        let walletCoreAddressValidator: AddressValidator = WalletCoreAddressService(coin: .bitcoin, publicKeyType: CoinType.bitcoin.publicKeyType)
        let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        #expect(walletCoreAddressValidator.validate(addressHex))
        #expect(addressValidator.validate(addressHex))
    }

    @Test(arguments: [
        "bc1q2ddhp55sq2l4xnqhpdv9xazg02v9dr7uu8c2p2",
        "MPmoY6RX3Y3HFjGEnFxyuLPCQdjvHwMEny",
        "abc",
        "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
        "175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W",
        "1111111111111111111114oLvT3\\n", // Messed up address
    ])
    func addressValidation_invalidAddresses(addressHex: String) {
        let walletCoreAddressValidator: AddressValidator
        walletCoreAddressValidator = WalletCoreAddressService(coin: .bitcoin, publicKeyType: CoinType.bitcoin.publicKeyType)
        let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        #expect(!walletCoreAddressValidator.validate(addressHex))
        #expect(!addressValidator.validate(addressHex))
    }
}
