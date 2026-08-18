//
//  EVMAddressUtilsTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct EVMAddressUtilsTests {
    private let ethereum = Blockchain.ethereum(testnet: false)

    @Test(arguments: EVMAddressUtils.Constants.burnAddresses)
    func burnAddressIsRejectedInEveryRepresentation(address: String) throws {
        let checksummed = try #require(EVMAddressUtils.toChecksumAddress(address))
        let body = address.dropFirst(2)

        #expect(EVMAddressUtils.isBurnAddress(address, blockchain: ethereum))
        #expect(EVMAddressUtils.isBurnAddress(checksummed, blockchain: ethereum))
        #expect(EVMAddressUtils.isBurnAddress("0x" + body.uppercased(), blockchain: ethereum))
        #expect(EVMAddressUtils.isBurnAddress("0X" + body, blockchain: ethereum))
        #expect(EVMAddressUtils.isBurnAddress(" \(address)\n", blockchain: ethereum))
        #expect(EVMAddressUtils.isBurnAddress(String(body), blockchain: ethereum))
        #expect(EVMAddressUtils.canonicalAddress(String(body), blockchain: ethereum) == address)
    }

    @Test(arguments: EVMAddressUtils.Constants.burnAddresses)
    func burnAddressIsRecognizedWithoutBlockchain(address: String) {
        let body = address.dropFirst(2)

        #expect(EVMAddressUtils.isBurnAddress(address))
        #expect(EVMAddressUtils.isBurnAddress(String(body)))
        #expect(EVMAddressUtils.isBurnAddress("0X" + body.uppercased()))
        #expect(EVMAddressUtils.isBurnAddress(" \(address)\n"))
        #expect(!EVMAddressUtils.isBurnAddress("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"))
    }

    @Test(arguments: EVMAddressUtils.Constants.burnAddresses)
    func burnAddressIsNotAValidAddress(address: String) {
        let evmAddressService = EVMAddressService()
        let body = address.dropFirst(2)

        #expect(!evmAddressService.validate(address))
        #expect(!evmAddressService.validate("0x" + body.uppercased()))
        #expect(!QuaiAddressService().validate(address))
        #expect(!XDCAddressService().validate("xdc" + body))
    }

    @Test(arguments: EVMAddressUtils.Constants.burnAddresses)
    func xdcBurnAddressIsRejected(address: String) {
        let body = address.dropFirst(2)
        let xdc = Blockchain.xdc(testnet: false)

        #expect(EVMAddressUtils.isBurnAddress("xdc" + body, blockchain: xdc))
        #expect(EVMAddressUtils.isBurnAddress("XDC" + body, blockchain: xdc))
    }

    @Test(arguments: EVMAddressUtils.Constants.burnAddresses)
    func xdcAddressCanonicalizesFromEveryForm(address: String) {
        let body = String(address.dropFirst(2))
        let xdc = Blockchain.xdc(testnet: false)

        #expect(EVMAddressUtils.canonicalAddress("xdc" + body, blockchain: xdc) == address)
        #expect(EVMAddressUtils.canonicalAddress("XDC" + body, blockchain: xdc) == address)
        #expect(EVMAddressUtils.canonicalAddress(address, blockchain: xdc) == address)
        #expect(EVMAddressUtils.canonicalAddress(body, blockchain: xdc) == address)
    }

    @Test
    func decimalAddressCanonicalizesFromNativeForm() {
        let address = "d0122a5qy59f7qge7d6hkz4u389qmd0dsrh6a7qnx"

        #expect(EVMAddressUtils.canonicalAddress(address, blockchain: .decimal(testnet: false))?.isEvmAddress == true)
    }

    @Test
    func regularAddressIsAccepted() {
        let address = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"

        #expect(!EVMAddressUtils.isBurnAddress(address, blockchain: ethereum))
        #expect(EVMAddressUtils.canonicalAddress(address, blockchain: ethereum) == address.lowercased())
    }

    @Test(arguments: [
        "",
        "0x0",
        "0x00",
        "0x000000000000000000000000000000000000dEa", // 41 characters
        "0x000000000000000000000000000000000000dEaDD", // 43 characters
        "0x00000000000000000000000000000000000zdEaD", // non-hex character
        "vitalik.eth",
    ])
    func malformedAddressHasNoCanonicalForm(address: String) {
        #expect(EVMAddressUtils.canonicalAddress(address, blockchain: ethereum) == nil)
        #expect(!EVMAddressUtils.isBurnAddress(address, blockchain: ethereum))
    }

    @Test(arguments: EVMAddressUtils.Constants.burnAddresses)
    func nonEvmBlockchainIsNotHandled(address: String) {
        let solana = Blockchain.solana(curve: .ed25519, testnet: false)

        #expect(EVMAddressUtils.canonicalAddress(address, blockchain: solana) == nil)
        #expect(!EVMAddressUtils.isBurnAddress(address, blockchain: solana))
    }

    @Test(arguments: EVMAddressUtilsTests.checksummedAddresses)
    func addressIsValidInEverySupportedCasing(address: String) {
        let body = address.dropFirst(2)

        #expect(EVMAddressUtils.isValidAddressHex(value: address))
        #expect(EVMAddressUtils.isValidAddressHex(value: address.lowercased()))
        #expect(EVMAddressUtils.isValidAddressHex(value: "0x" + body.uppercased()))
    }

    @Test
    func mixedCaseAddressWithWrongChecksumIsRejected() {
        let address = "0x5AAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"

        #expect(EVMAddressUtils.toChecksumAddress(address) != address)
        #expect(!EVMAddressUtils.isValidAddressHex(value: address))
    }

    @Test(arguments: [
        "",
        "0X5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed", // uppercase hex prefix
        "5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed", // no hex prefix
        "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAe", // 41 characters
        "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAedd", // 43 characters
    ])
    func addressWithoutValidHexShapeIsRejected(address: String) {
        #expect(!EVMAddressUtils.isValidAddressHex(value: address))
    }

    @Test(arguments: EVMAddressUtilsTests.checksummedAddresses)
    func checksumIsProducedFromEveryCasing(address: String) {
        let body = address.dropFirst(2)

        #expect(EVMAddressUtils.toChecksumAddress(address) == address)
        #expect(EVMAddressUtils.toChecksumAddress(address.lowercased()) == address)
        #expect(EVMAddressUtils.toChecksumAddress("0x" + body.uppercased()) == address)
        #expect(EVMAddressUtils.toChecksumAddress(String(body)) == address)
    }
}

private extension EVMAddressUtilsTests {
    static let checksummedAddresses = [
        "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
        "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
        "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
        "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb",
    ]
}
