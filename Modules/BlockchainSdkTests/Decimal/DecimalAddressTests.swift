//
//  DecimalAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Testing
@testable import BlockchainSdk

struct DecimalAddressTests {
    @Test
    func defaultAddressGeneration() throws {
        let walletPublicKey = Data(hexString: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")

        let addressService = DecimalAddressService()
        let plainAddress = try addressService.makeAddress(from: walletPublicKey)

        let expectedAddress = "d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9"

        #expect(plainAddress.value == expectedAddress)
    }

    @Test(.serialized, arguments: [
        "0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B",
        "d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9",
    ])
    func addressValidation_validAddresses(address: String) throws {
        #expect(DecimalAddressService().validate(address))
    }

    @Test(.serialized, arguments: [
        "0xc63763572D45171e4C25cA0818b4",
        "d01ccmkx4edg5t3unp9egyp3dzwtht",
        "",
    ])
    func addressValidation_invalidAddresses(address: String) {
        #expect(!DecimalAddressService().validate(address))
    }

    @Test
    func invalidCurveGeneration_throwsError() throws {
        #expect(throws: (any Error).self) {
            try DecimalAddressService().makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test
    func validateConverterAddressUtils() throws {
        let converter = DecimalAddressConverter()

        let ercAddress = try converter.convertToDecimalAddress("0xc63763572d45171e4c25ca0818b44e5dd7f5c15b")
        #expect(ercAddress == "d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9")

        let dscAddress = try converter.convertToETHAddress("d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9")
        #expect(dscAddress == "0xc63763572d45171e4c25ca0818b44e5dd7f5c15b")
    }
}
