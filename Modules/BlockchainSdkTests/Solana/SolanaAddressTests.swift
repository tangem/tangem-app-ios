//
//  SolanaAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemSdk
import Testing
import enum WalletCore.CoinType
@testable import BlockchainSdk

struct SolanaAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()

    @Test(arguments: [EllipticCurve.ed25519, .ed25519_slip0010])
    func defaultAddressGeneration(curve: EllipticCurve) throws {
        let key = Data(hexString: "0300000000000000000000000000000000000000000000000000000000000000")
        let blockchain = Blockchain.solana(curve: curve, testnet: false)
        let service = SolanaAddressService()

        let addrs = try service.makeAddress(from: key)

        #expect(addrs.value == "CiDwVBFgWV9E5MvXWoLgnEgn2hK7rJikbvfWavzAQz3")

        let addrFromTangemKey = try service.makeAddress(from: Keys.AddressesKeys.edKey)
        #expect(addrFromTangemKey.value == "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ")

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.edKey, for: blockchain) == addrFromTangemKey.value)

        // From WalletCore
        #expect(service.validate("2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpdST")) // OK
        #expect(!service.validate("2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpdSl")) // Contains invalid base-58 character
        #expect(!service.validate("2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpd")) // Is invalid length

        #expect(!service.validate("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")) // Ethereum address

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test(arguments: [
        "7v91N7iZ9mNicL8WfG6cgSCKyRXydQjLh6UYBWwm6y1Q",
        "EN2sCsJ1WDV8UFqsiTXHcUPUxQ4juE71eCknHYYMifkd",
    ])
    func validAddresses(addressHex: String) {
        let walletCoreAddressValidator: AddressValidator = WalletCoreAddressService(coin: .solana, publicKeyType: CoinType.solana.publicKeyType)

        [EllipticCurve.ed25519, .ed25519_slip0010].forEach {
            let addressValidator = AddressServiceFactory(blockchain: .solana(curve: $0, testnet: false)).makeAddressService()

            #expect(walletCoreAddressValidator.validate(addressHex))
            #expect(addressValidator.validate(addressHex))
        }
    }
}
