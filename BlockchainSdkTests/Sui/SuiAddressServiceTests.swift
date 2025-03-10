//
//  SuiAddressServiceTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct SuiAddressServiceTests {
    private static let invalidEmptyAddress = ""
    private static let invalidAddressOfOneByte = "0x00"
    private static let invalidAddressOf65Chars = "0x000000000000000000000000000000000000000000000000000000000000000"
    private static let invalidBase58StringAddress = "KsyS8YwkagyWZsQeMYNbf7Si9QkFZy1ZkK7ARqoqxAsjtFgGGxMqkKEPGg7GbhiRg4jhfb7RgU1fxdxaycd6F52qTf"

    private static let invalidAddresses = [
        invalidEmptyAddress,
        invalidAddressOfOneByte,
        invalidAddressOf65Chars,
        invalidBase58StringAddress,
    ]

    @Test
    func makeAddressCreatesCorrectAddressValue() throws {
        let seedKey = Data(hex: "85ebd1441fe4f954fbe5dc6077bf008e119a5e269297c6f7083d001d2ac876fe")
        let walletPublicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: nil)
        let expectedAddressValue = "0x54e80d76d790c277f5a44f3ce92f53d26f5894892bf395dee6375988876be6b2"

        let sut = SuiAddressService()
        let address = try sut.makeAddress(for: walletPublicKey, with: .default)

        #expect(address.value == expectedAddressValue)
    }

    @Test
    func validateShouldSucceedForCorrectAddress() {
        let correctAddressOf32Bytes = "0x54e80d76d790c277f5a44f3ce92f53d26f5894892bf395dee6375988876be6b2"
        let sut = SuiAddressService()

        #expect(sut.validate(correctAddressOf32Bytes))
    }

    @Test(arguments: invalidAddresses)
    func validateShouldFailForInvalidAddress(invalidAddress: String) {
        let sut = SuiAddressService()

        #expect(sut.validate(invalidAddress) == false)
    }
}
