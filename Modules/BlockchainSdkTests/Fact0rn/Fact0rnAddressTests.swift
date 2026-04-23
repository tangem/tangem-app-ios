//
//  Fact0rnAddressTests.swift
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

struct Fact0rnAddressTests {
    private let addressService = AddressServiceFactory(blockchain: .fact0rn).makeAddressService()

    @Test
    func defaultAddressGeneration() throws {
        let walletPublicKey = Data(hexString: "03B6D7E1FB0977A5881A3B1F64F9778B4F56CB2B9EFD6E0D03E60051EAFEBF5831")
        let expectedAddress = "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey"
        let address = try addressService.makeAddress(from: walletPublicKey)

        #expect(address.value == expectedAddress)
    }

    @Test
    func makeScriptHashFromAddress() throws {
        // given
        let converter = ElectrumScriptHashConverter(lockingScriptBuilder: .fact0rn())
        let address = "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey"

        // when
        let scriptHash = try converter.prepareScriptHash(address: address)

        // then
        let expectedScriptHash = "808171256649754B402099695833B95E4507019B3E494A7DBC6F62058F09050E"
        #expect(scriptHash == expectedScriptHash)
    }

    @Test(arguments: [
        "fact1qsev9cuanvdqwuh3gnkjaqdtjkeqcw5smex9dyx",
        "fact1qpr0t2aaus7wkerkhpqw4kh6z65pf33zcawx9t0",
        "fact1qsufztqay97de6073cxjd256mu6n9ruylydpzxf",
        "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey",
    ])
    func validAddresses(address: String) {
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "",
        "1q3n6x7kgsup6zlmpmndppx6ymtk6hxh4lnttt3y",
        "fact",
    ])
    func invalidAddresses(address: String) {
        #expect(!addressService.validate(address))
    }
}
