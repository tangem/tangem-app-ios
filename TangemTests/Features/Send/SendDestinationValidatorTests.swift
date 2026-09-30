//
//  SendDestinationValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("SendDestinationValidator")
struct SendDestinationValidatorTests {
    private enum TestData {
        static let blockchain = Blockchain.ethereum(testnet: false)
        static let walletAddress = "0x8ba1f109551bD432803012645Ac136ddd64DBA72"
        static let usdcContractAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
        static let otherAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
    }

    @Test("Token contract address is rejected as a destination")
    func rejectsTokenContractAddress() {
        let sut = makeSUT(tokenContractAddress: TestData.usdcContractAddress)

        #expect(throws: SendAddressServiceError.tokenContractAddress) {
            try sut.validate(destination: TestData.usdcContractAddress)
        }
    }

    @Test("Token contract address is matched case-insensitively for EVM")
    func rejectsTokenContractAddressRegardlessOfCase() {
        let sut = makeSUT(tokenContractAddress: TestData.usdcContractAddress)

        #expect(throws: SendAddressServiceError.tokenContractAddress) {
            try sut.validate(destination: TestData.usdcContractAddress.lowercased())
        }
    }

    @Test("Regular address passes when a token contract address is configured")
    func acceptsRegularAddressWithTokenContractConfigured() throws {
        let sut = makeSUT(tokenContractAddress: TestData.usdcContractAddress)

        try sut.validate(destination: TestData.otherAddress)
    }

    @Test("Coin send has no token contract to guard against")
    func acceptsContractLikeAddressForCoinSend() throws {
        let sut = makeSUT(tokenContractAddress: nil)

        try sut.validate(destination: TestData.usdcContractAddress)
    }

    @Test("Own wallet address is still rejected first")
    func rejectsOwnAddress() {
        let sut = makeSUT(tokenContractAddress: TestData.usdcContractAddress)

        #expect(throws: SendAddressServiceError.sameAsWalletAddress) {
            try sut.validate(destination: TestData.walletAddress)
        }
    }

    // MARK: - Helpers

    private func makeSUT(tokenContractAddress: String?) -> CommonSendDestinationValidator {
        CommonSendDestinationValidator(
            walletAddresses: [TestData.walletAddress],
            tokenContractAddress: tokenContractAddress,
            addressService: AddressServiceFactory(blockchain: TestData.blockchain).makeAddressService(),
            allowSameAddressTransaction: false,
            blockchain: TestData.blockchain
        )
    }
}
