//
//  YieldLendingTransactionProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("YieldLendingTransactionProvider")
final class YieldLendingTransactionProviderTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let yieldModule = "0x1111111111111111111111111111111111111111"
    private static let factory = "0x2222222222222222222222222222222222222222"
    private static let owner = "0x3333333333333333333333333333333333333333"
    private static let wrappedNative = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    private static let upgradeImplementation = "0xaaF16358336a5e292b1D70057f99c3f2e8241C63"

    @Test("A deposit calls the module's native entry, with no approval")
    func deposit() {
        #expect(YieldLendingTransactionProvider.depositCallData(upgradeImplementation: nil).hex() == "0921ecd4")
    }

    @Test("A deposit into a module that needs an upgrade carries the deposit inside the upgrade")
    func depositWithUpgrade() {
        let data = YieldLendingTransactionProvider.depositCallData(upgradeImplementation: Self.upgradeImplementation)

        #expect(data.hex() == Self.upgradeCall(wrapping: "0921ecd4"))
    }

    @Test("Withdrawing part of the position withdraws exactly that amount in wei", arguments: ["0.4", "0.40000000000000000099"])
    func partialWithdrawal(amount: String) throws {
        let value = try #require(Decimal(string: amount))

        let data = try YieldLendingTransactionProvider.withdrawCallData(.partial(value), blockchain: Self.blockchain, upgradeImplementation: nil)

        #expect(data.hex() == "84276d81000000000000000000000000000000000000000000000000058d15e176280000")
    }

    @Test("A partial withdrawal from a module that needs an upgrade carries the withdrawal inside the upgrade")
    func partialWithdrawalWithUpgrade() throws {
        let value = try #require(Decimal(string: "0.2"))

        let data = try YieldLendingTransactionProvider.withdrawCallData(
            .partial(value),
            blockchain: Self.blockchain,
            upgradeImplementation: Self.upgradeImplementation
        )

        #expect(data.hex() == Self.upgradeCall(wrapping: "84276d81" + Self.word("2c68af0bb140000")))
    }

    @Test("Withdrawing everything closes the position, however much it has grown since it was read")
    func fullWithdrawal() throws {
        let data = try YieldLendingTransactionProvider.withdrawCallData(.all, blockchain: Self.blockchain, upgradeImplementation: nil)

        #expect(data.hex() == "4423380d")
    }

    @Test("A partial withdrawal of less than a wei is rejected instead of sending nothing", arguments: ["0", "0.0000000000000000009", "-1"])
    func emptyPartialWithdrawal(amount: String) throws {
        let value = try #require(Decimal(string: amount))

        #expect(throws: ValidationError.invalidAmount) {
            try YieldLendingTransactionProvider.withdrawCallData(.partial(value), blockchain: Self.blockchain, upgradeImplementation: nil)
        }
    }

    @Test("A user without a module deploys one for WETH through the factory, with no approval and no processor fee")
    func deploy() {
        let call = Self.preparationCall(.deployModule)

        #expect(call.destination == Self.factory)
        #expect(call.data.hex() == "cbeda14c" + Self.word(Self.owner) + Self.word(Self.wrappedNative) + Self.word("0"))
    }

    @Test("WETH that was never set up is initialised on the module, with no approval and no processor fee")
    func initToken() {
        let call = Self.preparationCall(.initializeToken(upgradeImplementation: nil))

        #expect(call.destination == Self.yieldModule)
        #expect(call.data.hex() == "ebd4b81c" + Self.word(Self.wrappedNative) + Self.word("0"))
    }

    @Test("Initialising WETH on a module that needs an upgrade carries the initialisation inside the upgrade")
    func initTokenWithUpgrade() {
        let call = Self.preparationCall(.initializeToken(upgradeImplementation: Self.upgradeImplementation))

        #expect(call.destination == Self.yieldModule)
        #expect(call.data.hex() == Self.upgradeCall(wrapping: "ebd4b81c" + Self.word(Self.wrappedNative) + Self.word("0")))
    }

    @Test("WETH left inactive by a full withdrawal is reactivated on the module, with no approval and no processor fee")
    func reactivateToken() {
        let call = Self.preparationCall(.reactivateToken(upgradeImplementation: nil))

        #expect(call.destination == Self.yieldModule)
        #expect(call.data.hex() == "c478e956" + Self.word(Self.wrappedNative) + Self.word("0"))
    }

    @Test("Reactivating WETH on a module that needs an upgrade carries the reactivation inside the upgrade")
    func reactivateTokenWithUpgrade() {
        let call = Self.preparationCall(.reactivateToken(upgradeImplementation: Self.upgradeImplementation))

        #expect(call.destination == Self.yieldModule)
        #expect(call.data.hex() == Self.upgradeCall(wrapping: "c478e956" + Self.word(Self.wrappedNative) + Self.word("0")))
    }
}

// MARK: - Fixtures

private extension YieldLendingTransactionProviderTests {
    static func preparationCall(_ preparation: LendingDepositPreparation) -> (destination: String, data: Data) {
        YieldLendingTransactionProvider.preparationCall(
            preparation,
            owner: owner,
            yieldModule: yieldModule,
            wrappedNative: wrappedNative,
            factory: factory
        )
    }

    static func word(_ value: String) -> String {
        let hex = value.lowercased().removeHexPrefix()
        return String(repeating: "0", count: 64 - hex.count) + hex
    }

    static func upgradeCall(wrapping call: String) -> String {
        let padding = String(repeating: "0", count: (64 - call.count % 64) % 64)
        return "4f1ef286" + word(upgradeImplementation) + word("40") + word(String(call.count / 2, radix: 16)) + call + padding
    }
}
