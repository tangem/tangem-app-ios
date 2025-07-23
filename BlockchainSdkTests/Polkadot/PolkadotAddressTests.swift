//
//  PolkdotAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import CryptoKit
import TangemSdk
import Testing
import enum WalletCore.CoinType
@testable import BlockchainSdk

struct PolkadotAddressTests {
    private let curves = [EllipticCurve.ed25519, .ed25519_slip0010]

    @Test
    func defaultAddressGeneration() throws {
        // From trust wallet `PolkadotTests.swift`
        let privateKey = Data(hexString: "0xd65ed4c1a742699b2e20c0c1f1fe780878b1b9f7d387f934fe0a7dc36f1f9008")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .polkadot(curve: .ed25519, testnet: false),
            publicKey: publicKey,
            expectedAddress: "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .polkadot(curve: .ed25519_slip0010, testnet: false),
            publicKey: publicKey,
            expectedAddress: "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .polkadot(curve: .ed25519, testnet: false),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "14cermZiQ83ihmHKkAucgBT2sqiRVvd4rwqBGqrMnowAKYRp"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .polkadot(curve: .ed25519_slip0010, testnet: false),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "14cermZiQ83ihmHKkAucgBT2sqiRVvd4rwqBGqrMnowAKYRp"
        )
    }

    @Test
    func defaultAddressGeneration_kusama() throws {
        // From trust wallet `KusamaTests.swift`
        let privateKey = Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        try PolkadotNetworkTesting.testSubstrateNetwork(
            .kusama(curve: .ed25519),
            publicKey: publicKey,
            expectedAddress: "HewiDTQv92L2bVtkziZC8ASxrFUxr6ajQ62RXAnwQ8FDVmg"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .kusama(curve: .ed25519_slip0010),
            publicKey: publicKey,
            expectedAddress: "HewiDTQv92L2bVtkziZC8ASxrFUxr6ajQ62RXAnwQ8FDVmg"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .kusama(curve: .ed25519),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "GByNkeXAhoB1t6FZEffRyytAp11cHt7EpwSWD8xiX88tLdQ"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .kusama(curve: .ed25519_slip0010),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "GByNkeXAhoB1t6FZEffRyytAp11cHt7EpwSWD8xiX88tLdQ"
        )
    }

    @Test
    func defaultAddressGeneration_westend() throws {
        try PolkadotNetworkTesting.testSubstrateNetwork(
            .polkadot(curve: .ed25519, testnet: true),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .polkadot(curve: .ed25519_slip0010, testnet: true),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }

    @Test
    func defaultAddressGeneration_azero() throws {
        try PolkadotNetworkTesting.testSubstrateNetwork(
            .azero(curve: .ed25519, testnet: true),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .azero(curve: .ed25519_slip0010, testnet: true),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }

    @Test(arguments: [
        "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW",
        "14PhJGbzPxhQbiq7k9uFjDQx3MNiYxnjFRSiVBvBBBfnkAoM",
    ])
    func validAddresses(addressHex: String) {
        curves.forEach {
            let addressValidator = AddressServiceFactory(blockchain: .polkadot(curve: $0, testnet: false)).makeAddressService()
            #expect(addressValidator.validate(addressHex))
        }
    }

    @Test(arguments: [
        "cosmos1l4f4max9w06gqrvsxf74hhyzuqhu2l3zyf0480",
        "3317oFJC9FvxU2fwrKVsvgnMGCDzTZ5nyf",
        "ELmaX1aPkyEF7TSmYbbyCjmSgrBpGHv9EtpwR2tk1kmpwvG",
    ])
    func invalidAddresses(addressHex: String) {
        curves.forEach {
            let addressValidator = AddressServiceFactory(blockchain: .polkadot(curve: $0, testnet: false)).makeAddressService()
            #expect(!addressValidator.validate(addressHex))
        }
    }
}
