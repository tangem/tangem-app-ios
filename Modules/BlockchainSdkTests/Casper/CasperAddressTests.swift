//
//  CasperAddressTests.swift
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

struct CasperAddressTests {
    @Test
    func defaultAddressGeneration() throws {
        // given
        let ed25519WalletPublicKey = Data(hexString: "98C07D7E72D89A681D7227A7AF8A6FD5F22FE0105C8741D55A95DF415454B82E")
        let ed25519ExpectedAddress = "0198c07D7e72D89A681d7227a7Af8A6fd5F22fe0105c8741d55A95dF415454b82E"

        let ed25519AddressService = CasperAddressService(curve: .ed25519)
        let secp256k1AddressService = CasperAddressService(curve: .secp256k1)

        // when
        let secp256k1WalletPublicKey = Data(hexString: "021F997DFBBFD32817C0E110EAEE26BCBD2BB70B4640C515D9721C9664312EACD8")
        let secp256k1ExpectedAddress = "02021f997DfbbFd32817C0E110EAeE26BCbD2BB70b4640C515D9721c9664312eaCd8"

        // then
        try #expect(ed25519AddressService.makeAddress(from: ed25519WalletPublicKey).value == ed25519ExpectedAddress)
        try #expect(secp256k1AddressService.makeAddress(from: secp256k1WalletPublicKey, type: .default).value == secp256k1ExpectedAddress)
    }

    @Test(.serialized, arguments: [
        "0198c07D7e72D89A681d7227a7Af8A6fd5F22fe0105c8741d55A95dF415454b82E",
    ])
    func addressValidation_validAddresses_ed25519(address: String) {
        let ed25519AddressService = CasperAddressService(curve: .ed25519)
        #expect(ed25519AddressService.validate(address))
    }

    @Test(.serialized, arguments: [
        "02021f997DfbbFd32817C0E110EAeE26BCbD2BB70b4640C515D9721c9664312eaCd8",
    ])
    func addressValidation_validAddresses_secp256k1(address: String) {
        let secp256k1AddressService = CasperAddressService(curve: .secp256k1)
        #expect(secp256k1AddressService.validate(address))
    }
}
