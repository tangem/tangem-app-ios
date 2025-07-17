//
//  EthereumAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoKit
import WalletCore
import class WalletCore.PrivateKey
@testable import BlockchainSdk
import Testing

struct EthereumAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()

    @Test(.serialized, arguments: Constants.defaultBlockchainArgs)
    func defaultAddressGeneration(blockchain: BlockchainSdk.Blockchain) throws {
        // given
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        // when
        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        // then
        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.type == addr_comp.type)
        #expect(addr_dec.value == "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        #expect("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased() == "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum

        let trustWalletAddress = try addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpDecompressedKey, for: blockchain)
        #expect(trustWalletAddress == addr_dec.value)

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(.serialized, arguments: Constants.defaultBlockchainArgs)
    func defaultAddressGeneration2(blockchain: BlockchainSdk.Blockchain) throws {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let walletPubKey = Data(hex: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")
        let expectedAddress = "0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"
        let address = try addressService.makeAddress(from: walletPubKey).value

        #expect(address == expectedAddress)
    }

    @Test(.serialized, arguments: Constants.defaultBlockchainArgs)
    func testnetAddressGeneration(blockchain: BlockchainSdk.Blockchain) throws {
        // given
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        // when
        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        // then
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.type == addr_comp.type)
        #expect(addr_dec.value == "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        #expect("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased() == "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum
    }

    @Test(.serialized, arguments: Constants.defaultBlockchainArgs)
    func ethChecksum(blockchain: BlockchainSdk.Blockchain) throws {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        let chesksummed = EthereumAddressUtils.toChecksumAddress("0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359")
        #expect(chesksummed == "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")

        let testCases = [
            "0x52908400098527886E0F7030069857D2E4169EE7",
            "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
            "0xde709f2102306220921060314715629080e2fb77",
            "0x27b1fdb04752bbc536007a920d24acb045561c26",
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
            "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
        ]

        _ = testCases.map {
            let checksummed = EthereumAddressUtils.toChecksumAddress($0)
            #expect(checksummed != nil)
            #expect(addressService.validate($0))
            #expect(addressService.validate(checksummed!))
        }
    }

    @Test(.serialized, arguments: Constants.defaultBlockchainArgs)
    func validAddresses(blockchain: BlockchainSdk.Blockchain) {
        let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let testCases = [
            "0xeDe8F58dADa22c3A49dB60D4f82BAD428ab65F89",
            "0x52908400098527886E0F7030069857D2E4169EE7",
            "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
            "0xde709f2102306220921060314715629080e2fb77",
            "0x27b1fdb04752bbc536007a920d24acb045561c26",
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
            "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
            "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d",
            "0xc63763572d45171e4c25ca0818b44e5dd7f5c15b",
        ]

        testCases.forEach {
            #expect(addressValidator.validate($0))
        }
    }

    @Test(.serialized, arguments: Constants.defaultBlockchainArgs)
    func invalidAddresses(blockchain: BlockchainSdk.Blockchain) {
        let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let testCases = [
            "ede8f58dada22a49db60d4f82bad428ab65f89",
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9adb",
            "0X6ECa00c52AFC728CDbF42E817d712e175bb23C7d",
        ]

        _ = testCases.map {
            #expect(!addressValidator.validate($0))
        }
    }

    @Test(.serialized, arguments: Constants.defaultBlockchainArgs)
    func ensAddressValidation(blockchain: BlockchainSdk.Blockchain) throws {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        // Valid ENS addresses
        let validEnsAddresses = [
            "vitalik.eth",
            "ens.eth",
            "ethereum.eth",
            "test123.eth",
            "my-domain.eth",
            "subdomain.main.eth",
            "a.eth",
            "very-long-domain-name-with-many-characters.eth",
            "domain-with-numbers123.eth",
        ]

        for ensAddress in validEnsAddresses {
            let validateResult = addressService.validate(ensAddress)

            if addressService is EthereumAddressService {
                #expect(validateResult, "ENS address \(ensAddress) should be valid")
            } else {
                #expect(!validateResult, "ENS address \(ensAddress) should be unvalid")
            }
        }

        // Invalid ENS addresses
        let invalidEnsAddresses = [
            ".eth", // Empty domain
            "eth", // No TLD
            "domain..eth", // Double dot
            "domain.eth.", // Trailing dot
            ".domain.eth", // Leading dot
            "domain.eth..", // Multiple trailing dots
            "domain.eth/", // Invalid character
            "domain.eth?", // Invalid character
            "domain.eth#", // Invalid character
            "domain.eth@", // Invalid character
            "domain.eth!", // Invalid character
            "domain.eth$", // Invalid character
            "domain.eth%", // Invalid character
            "domain.eth^", // Invalid character
            "domain.eth&", // Invalid character
            "domain.eth*", // Invalid character
            "domain.eth(", // Invalid character
            "domain.eth)", // Invalid character
            "domain.eth+", // Invalid character
            "domain.eth=", // Invalid character
            "domain.eth[", // Invalid character
            "domain.eth]", // Invalid character
            "domain.eth{", // Invalid character
            "domain.eth}", // Invalid character
            "domain.eth|", // Invalid character
            "domain.eth\\", // Invalid character
            "domain.eth:", // Invalid character
            "domain.eth;", // Invalid character
            "domain.eth\"", // Invalid character
            "domain.eth'", // Invalid character
            "domain.eth<", // Invalid character
            "domain.eth>", // Invalid character
            "domain.eth,", // Invalid character
            "domain.eth.", // Trailing dot
            "domain.eth..", // Multiple trailing dots
            "domain..eth", // Double dot
            "domain...eth", // Multiple dots
        ]

        for ensAddress in invalidEnsAddresses {
            #expect(!addressService.validate(ensAddress), "ENS address \(ensAddress) should be invalid")
        }
    }
}

extension EthereumAddressTests {
    enum Constants {
        static let defaultBlockchainArgs: [BlockchainSdk.Blockchain] = [.polygon(testnet: false), .ethereum(testnet: false)]
    }
}
