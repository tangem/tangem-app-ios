//
//  TronDEXTransactionMapperTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import TangemExpress
@testable import Tangem

@Suite("TronDEXTransactionMapper — provider raw transaction validation")
struct TronDEXTransactionMapperTests {
    private let mapper = TronDEXTransactionMapper(blockchain: .tron(testnet: false))

    private var ownerAddress: String { "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW" }
    private var routerAddress: String { "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt" }
    private var depositChannelAddress: String { "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6" }

    @Test("lifts the contract call out of the provider transaction")
    func map_validProviderTransaction() throws {
        let call = try mapContractCall(
            data: makeExpressTransactionData(),
            expectedOwner: ownerAddress
        )

        #expect(call.contractAddress == routerAddress)
        #expect(call.callData.count == 1476)
        #expect(call.callData.prefix(4) == Data([0x31, 0x10, 0xC7, 0xB9]))
        #expect(call.callValue == 0)
        #expect(call.feeLimit == 150_000_000)
        #expect(call.memo == nil)
    }

    @Test("lifts the embedded memo out of a THORChain-routed provider transaction")
    func map_swapKitTransaction_carriesMemo() throws {
        let data = makeExpressTransactionData(
            destinationAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            txData: "0x" + TronDEXFixtures.swapKitRawTransactionHex
        )

        let call = try mapContractCall(data: data, expectedOwner: ownerAddress)

        #expect(call.memo == TronDEXFixtures.swapKitMemo)
        #expect(call.feeLimit == 10_000_000)
        #expect(call.callData.prefix(4) == Data([0xA9, 0x05, 0x9C, 0xBB]))
    }

    @Test("falls back to extraDestinationId when the transaction has no embedded memo")
    func map_noEmbeddedMemo_fallsBackToExtraDestinationId() throws {
        let data = makeExpressTransactionData(extraDestinationId: "fallback-extra-id")

        let call = try mapContractCall(data: data, expectedOwner: ownerAddress)

        #expect(call.memo == "fallback-extra-id")
    }

    @Test("lifts a plain coin transfer out of a TRX-coin provider transaction")
    func map_transferTransaction() throws {
        let data = makeTransferExpressTransactionData()

        let mapped = try mapper.map(data: data, expectedOwner: ownerAddress)

        guard case .transfer(let transfer) = mapped else {
            Issue.record("Expected a transfer, got \(mapped)")
            return
        }

        #expect(transfer.destinationAddress == depositChannelAddress)
        #expect(transfer.amount == 50)
        #expect(transfer.memo == nil)
    }

    @Test("a transfer without an embedded memo falls back to extraDestinationId")
    func map_transferTransaction_fallsBackToExtraDestinationId() throws {
        let data = makeTransferExpressTransactionData(extraDestinationId: "fallback-extra-id")

        let mapped = try mapper.map(data: data, expectedOwner: nil)

        guard case .transfer(let transfer) = mapped else {
            Issue.record("Expected a transfer, got \(mapped)")
            return
        }

        #expect(transfer.memo == "fallback-extra-id")
    }

    @Test("a transfer to a different address than the DTO destination is rejected")
    func map_transferDestinationMismatch_throws() {
        let data = makeTransferExpressTransactionData(destinationAddress: routerAddress)

        #expect(throws: TronDEXTransactionMapperError.destinationAddressMismatch) {
            _ = try mapper.map(data: data, expectedOwner: nil)
        }
    }

    @Test("a transfer moving a different amount than the DTO declares is rejected")
    func map_transferAmountMismatch_throws() {
        let data = makeTransferExpressTransactionData(txValue: 49)

        #expect(throws: TronDEXTransactionMapperError.valueMismatch) {
            _ = try mapper.map(data: data, expectedOwner: nil)
        }
    }

    @Test("a transfer built for a different owner is rejected")
    func map_transferOwnerMismatch_throws() {
        #expect(throws: TronDEXTransactionMapperError.ownerAddressMismatch) {
            _ = try mapper.map(
                data: makeTransferExpressTransactionData(),
                expectedOwner: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF"
            )
        }
    }

    @Test("a call targeting a different contract than the DTO destination is rejected")
    func map_callDestinationMismatch_throws() {
        let data = makeExpressTransactionData(destinationAddress: "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn")

        #expect(throws: TronDEXTransactionMapperError.destinationAddressMismatch) {
            _ = try mapper.map(data: data, expectedOwner: nil)
        }
    }

    @Test("a call moving a different TRX value than the DTO declares is rejected")
    func map_callValueMismatch_throws() {
        let data = makeExpressTransactionData(txValue: 1)

        #expect(throws: TronDEXTransactionMapperError.valueMismatch) {
            _ = try mapper.map(data: data, expectedOwner: nil)
        }
    }

    @Test("a call built for a different owner is rejected")
    func map_ownerMismatch_throws() {
        #expect(throws: TronDEXTransactionMapperError.ownerAddressMismatch) {
            _ = try mapper.map(
                data: makeExpressTransactionData(),
                expectedOwner: "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF"
            )
        }
    }

    @Test("missing txData is rejected")
    func map_missingTxData_throws() {
        let data = makeExpressTransactionData(txData: nil)

        do {
            _ = try mapper.map(data: data, expectedOwner: nil)
            Issue.record("Expected map to throw transactionDataNotFound")
        } catch ExpressProviderError.transactionDataNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("plain EVM calldata in txData is rejected")
    func map_plainCalldata_throws() {
        let data = makeExpressTransactionData(txData: "0xa9059cbb00ff")

        #expect(throws: TronRawTransactionParserError.self) {
            _ = try mapper.map(data: data, expectedOwner: nil)
        }
    }

    @Test(
        "the fee limit never drops below the estimated fee",
        arguments: [
            (feeTRX: Decimal(string: "16.000001")!, expectedLimit: Int64(16_000_001)),
            (feeTRX: Decimal(string: "10")!, expectedLimit: Int64(10_000_000)),
            (feeTRX: Decimal(string: "1.5")!, expectedLimit: Int64(10_000_000)),
            (feeTRX: Decimal(string: "10.0000005")!, expectedLimit: Int64(10_000_001)),
        ]
    )
    func adjustedFeeLimit_neverBelowEstimate(feeTRX: Decimal, expectedLimit: Int64) throws {
        let data = makeExpressTransactionData(
            destinationAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            txData: "0x" + TronDEXFixtures.swapKitRawTransactionHex
        )
        let call = try mapContractCall(data: data, expectedOwner: ownerAddress)

        let fee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: feeTRX))

        #expect(call.adjustedFeeLimit(covering: fee, blockchain: .tron(testnet: false)) == expectedLimit)
    }

    @Test(
        "an absent provider fee limit falls back to the default, floored by the estimate",
        arguments: [
            (feeTRX: Decimal(25), expectedLimit: Int64(100_000_000)),
            (feeTRX: Decimal(150), expectedLimit: Int64(150_000_000)),
        ]
    )
    func adjustedFeeLimit_absentProviderLimit_floorsAtDefault(feeTRX: Decimal, expectedLimit: Int64) {
        let call = TronDEXContractCall(contractAddress: routerAddress, callData: Data([0xAB]), callValue: 0, feeLimit: nil, memo: nil)
        let fee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: feeTRX))

        #expect(call.adjustedFeeLimit(covering: fee, blockchain: .tron(testnet: false)) == expectedLimit)
    }
}

// MARK: - Helpers

private extension TronDEXTransactionMapperTests {
    func mapContractCall(data: ExpressTransactionData, expectedOwner: String?) throws -> TronDEXContractCall {
        let mapped = try mapper.map(data: data, expectedOwner: expectedOwner)

        guard case .contractCall(let call) = mapped else {
            throw TestError.notAContractCall
        }

        return call
    }

    enum TestError: Error {
        case notAContractCall
    }

    func makeExpressTransactionData(
        destinationAddress: String = "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt",
        txValue: Decimal = .zero,
        txData: String? = "0x" + TronDEXFixtures.liFiRawTransactionHex,
        extraDestinationId: String? = nil
    ) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW",
            destinationAddress: destinationAddress,
            extraDestinationId: extraDestinationId,
            txValue: txValue,
            txData: txData,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }

    func makeTransferExpressTransactionData(
        destinationAddress: String = "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6",
        txValue: Decimal = 50,
        extraDestinationId: String? = nil
    ) -> ExpressTransactionData {
        makeExpressTransactionData(
            destinationAddress: destinationAddress,
            txValue: txValue,
            txData: TronDEXFixtures.swapKitTransferRawTransactionHex,
            extraDestinationId: extraDestinationId
        )
    }
}
