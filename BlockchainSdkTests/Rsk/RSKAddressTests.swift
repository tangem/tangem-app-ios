//
//  RSKAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

struct RSKAddressTests {
    @Test
    func rskChecksum() {
        let rskAddressService = RskAddressService()
        let publicKey = Data(hex: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")
        let chesksummed = try! rskAddressService.makeAddress(from: publicKey)

        #expect(chesksummed.value == "0xc63763572D45171E4C25cA0818B44e5DD7f5c15b")

        let correctAddress = "0xc63763572d45171e4c25ca0818b44e5dd7f5c15b"
        let correctAddressWithChecksum = "0xc63763572D45171E4C25cA0818B44e5DD7f5c15b"

        #expect(rskAddressService.validate(correctAddress))
        #expect(rskAddressService.validate(correctAddressWithChecksum))

        let incorrectAddress = "0Xc63763572d45171e4c25ca0818b44e5dd7f5c15b"
        let incorrectAddressWithChecksum = "0Xc63763572D45171E4C25cA0818B44e5DD7f5c15b"
        #expect(!rskAddressService.validate(incorrectAddress))
        #expect(!rskAddressService.validate(incorrectAddressWithChecksum))
    }
}
