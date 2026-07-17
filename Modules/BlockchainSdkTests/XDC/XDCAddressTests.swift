//
//  XDCAddressTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Testing
@testable import BlockchainSdk

struct XDCAddressTests {
    private let addressService = AddressServiceFactory(blockchain: .xdc(testnet: false)).makeAddressService()

    @Test
    func defaultAddressGeneration() throws {
        let walletPublicKey = Data(hexString: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")

        let plainAddress = try addressService.makeAddress(from: walletPublicKey)

        #expect(plainAddress.value == "xdcc63763572D45171e4C25cA0818b44E5Dd7F5c15B")
    }

    @Test(arguments: [
        "xdc0Ec42c2800729ECb65b748f4f3a168C958D41741",
        "0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B",
    ])
    func addressValidation_validAddresses(address: String) {
        #expect(addressService.validate(address))
    }

    @Test(arguments: [
        "xdc0Ec42c2800729ECb65b748f4f3a168C958D417",
        "vitalik.eth",
        "0x.eth",
        "",
    ])
    func addressValidation_invalidAddresses(address: String) {
        #expect(!addressService.validate(address))
    }

    @Test
    func invalidCurveGeneration_throwsError() throws {
        #expect(throws: (any Error).self) {
            try addressService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }
}
