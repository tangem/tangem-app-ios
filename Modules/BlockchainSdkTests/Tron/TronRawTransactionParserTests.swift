//
//  TronRawTransactionParserTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import SwiftProtobuf
@testable import BlockchainSdk

struct TronRawTransactionParserTests {
    /// A real LiFi-built Tron transaction delivered by Express as `txData`
    /// (USDT-TRC20 → USDT-ERC20 swap, NEAR-intents deposit call).
    @Test("parses the contract call out of a provider-built raw transaction")
    func parse_liFiTransaction() throws {
        let call = try #require(parseContractCall(Fixtures.liFiRawTransactionHex))

        #expect(call.ownerAddress == "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW")
        #expect(call.contractAddress == "TU3ymitEKCWQFtASkEeHaPb8NfZcJtCHLt")
        #expect(call.callData.count == 1476)
        #expect(call.callData.prefix(4) == Data([0x31, 0x10, 0xC7, 0xB9]))
        #expect(call.callValue == 0)
        #expect(call.feeLimit == 150_000_000)
        #expect(call.memo == nil)
    }

    /// A real SwapKit-built transaction: a TRC20 `transfer` to the THORChain inbound vault
    /// with the routing memo in `raw.data`.
    @Test("parses the routing memo out of a THORChain-routed provider transaction")
    func parse_swapKitTransaction_carriesMemo() throws {
        let call = try #require(parseContractCall(Fixtures.swapKitRawTransactionHex))

        #expect(call.ownerAddress == "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW")
        #expect(call.contractAddress == "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t")
        #expect(call.callData.prefix(4) == Data([0xA9, 0x05, 0x9C, 0xBB]))
        #expect(call.callValue == 0)
        #expect(call.feeLimit == 10_000_000)
        #expect(call.memo == "=:ETH.USDT:0xd7ABce6612079A05e431752cb85Bf7010E40FdF5:140119e4/1/0:-_/tan:0/144")
    }

    /// A real SwapKit-built transaction for a TRX-coin source: a plain `TransferContract`
    /// to a deposit-channel address, no memo.
    @Test("parses a plain coin transfer out of a provider-built raw transaction")
    func parse_swapKitTransferTransaction() throws {
        let parsed = try TronRawTransactionParser()
            .parse(rawTransaction: Data(hex: Fixtures.swapKitTransferRawTransactionHex))

        guard case .transfer(let transfer) = parsed else {
            Issue.record("Expected a transfer, got \(parsed)")
            return
        }

        #expect(transfer.ownerAddress == "TRbRnXcKrA9bkx1nnP3Z6pLJ2SDPdwRnBW")
        #expect(transfer.destinationAddress == "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6")
        #expect(transfer.amount == 50_000_000)
        #expect(transfer.memo == nil)
    }

    @Test("plain EVM calldata is rejected")
    func parse_evmCalldata_throws() {
        let evmCalldata = Data(hex: "a9059cbb000000000000000000000000ec8c5a0fcbb28f14418eed9cf582af0d77e4256e0000000000000000000000000000000000000000000000000000000005f5e100")

        #expect(throws: TronRawTransactionParserError.self) {
            _ = try TronRawTransactionParser().parse(rawTransaction: evmCalldata)
        }
    }

    @Test("a raw transaction without contracts is rejected")
    func parse_noContracts_throws() throws {
        let raw = Protocol_Transaction.raw()
        let serialized = try raw.serializedData()

        #expect(throws: TronRawTransactionParserError.unexpectedContractCount) {
            _ = try TronRawTransactionParser().parse(rawTransaction: serialized)
        }
    }

    @Test("a raw transaction with multiple contracts is rejected")
    func parse_multipleContracts_throws() throws {
        let transfer = try Protocol_TransferContract.with {
            $0.ownerAddress = try TronUtils().convertAddressToBytes("TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF")
            $0.toAddress = try TronUtils().convertAddressToBytes("TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn")
            $0.amount = 1
        }
        let contract = try Protocol_Transaction.Contract.with {
            $0.type = .transferContract
            $0.parameter = try Google_Protobuf_Any(message: transfer)
        }
        let raw = Protocol_Transaction.raw.with {
            $0.contract = [contract, contract]
        }
        let serialized = try raw.serializedData()

        #expect(throws: TronRawTransactionParserError.unexpectedContractCount) {
            _ = try TronRawTransactionParser().parse(rawTransaction: serialized)
        }
    }

    @Test("an unsupported contract type is rejected")
    func parse_unsupportedContractType_throws() throws {
        let raw = Protocol_Transaction.raw.with {
            $0.contract = [
                Protocol_Transaction.Contract.with { $0.type = .freezeBalanceV2Contract },
            ]
        }
        let serialized = try raw.serializedData()

        #expect(throws: TronRawTransactionParserError.unsupportedContractType) {
            _ = try TronRawTransactionParser().parse(rawTransaction: serialized)
        }
    }

    @Test("a transfer carries the transaction-level memo")
    func parse_transferWithMemo() throws {
        let transfer = try Protocol_TransferContract.with {
            $0.ownerAddress = try TronUtils().convertAddressToBytes("TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF")
            $0.toAddress = try TronUtils().convertAddressToBytes("TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn")
            $0.amount = 1_000_000
        }
        let raw = try Protocol_Transaction.raw.with {
            $0.contract = [
                try Protocol_Transaction.Contract.with {
                    $0.type = .transferContract
                    $0.parameter = try Google_Protobuf_Any(message: transfer)
                },
            ]
            $0.data = Data("=:ETH.ETH:0xd7ABce6612079A05e431752cb85Bf7010E40FdF5".utf8)
        }
        let serialized = try raw.serializedData()

        let parsed = try TronRawTransactionParser().parse(rawTransaction: serialized)

        guard case .transfer(let result) = parsed else {
            Issue.record("Expected a transfer, got \(parsed)")
            return
        }

        #expect(result.memo == "=:ETH.ETH:0xd7ABce6612079A05e431752cb85Bf7010E40FdF5")
        #expect(result.amount == 1_000_000)
    }

    @Test("a smart-contract call without calldata is rejected")
    func parse_emptyCallData_throws() throws {
        let call = try Protocol_TriggerSmartContract.with {
            $0.ownerAddress = try TronUtils().convertAddressToBytes("TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF")
            $0.contractAddress = try TronUtils().convertAddressToBytes("TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn")
        }
        let raw = try Protocol_Transaction.raw.with {
            $0.contract = [
                try Protocol_Transaction.Contract.with {
                    $0.type = .triggerSmartContract
                    $0.parameter = try Google_Protobuf_Any(message: call)
                },
            ]
        }
        let serialized = try raw.serializedData()

        #expect(throws: TronRawTransactionParserError.callDataNotFound) {
            _ = try TronRawTransactionParser().parse(rawTransaction: serialized)
        }
    }

    @Test("an absent fee limit maps to nil")
    func parse_absentFeeLimit_isNil() throws {
        let call = try Protocol_TriggerSmartContract.with {
            $0.ownerAddress = try TronUtils().convertAddressToBytes("TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF")
            $0.contractAddress = try TronUtils().convertAddressToBytes("TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn")
            $0.data = Data([0xA9, 0x05, 0x9C, 0xBB])
        }
        let raw = try Protocol_Transaction.raw.with {
            $0.contract = [
                try Protocol_Transaction.Contract.with {
                    $0.type = .triggerSmartContract
                    $0.parameter = try Google_Protobuf_Any(message: call)
                },
            ]
        }
        let serialized = try raw.serializedData()

        let parsed = try #require(parseContractCall(serialized.hex()))

        #expect(parsed.feeLimit == nil)
        #expect(parsed.callData == Data([0xA9, 0x05, 0x9C, 0xBB]))
    }

    private func parseContractCall(_ rawTransactionHex: String) -> TronRawTransactionParser.ContractCall? {
        guard
            let parsed = try? TronRawTransactionParser().parse(rawTransaction: Data(hex: rawTransactionHex)),
            case .contractCall(let call) = parsed
        else {
            return nil
        }

        return call
    }
}

// MARK: - Fixtures

/// Mirrored in `TangemTests/Features/Express/TronDEXFixtures.swift` — the targets can't share sources; keep in sync.
private enum Fixtures {
    // swiftformat:disable wrap
    static let swapKitRawTransactionHex = "0a02b5a82208a887e8d1ec0f7ce24088fdcf99fb33524f3d3a4554482e555344543a3078643741426365363631323037394130356534333137353263623835426637303130453430466446353a31343031313965342f312f303a2d5f2f74616e3a302f3134345aae01081f12a9010a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412740a1541ab63886b97ccb4cadb942ceb09c3c01a4c6953e8121541a614f803b6fd780986a42c78ec9c7f77e6ded13c2244a9059cbb00000000000000000000000015a18266c5331ac3a7f6bc5cdf25bcc55561b4fa0000000000000000000000000000000000000000000000000000000000e4e1c070e6d9bd99fb33900180ade204"

    static let swapKitTransferRawTransactionHex = "0a0218512208ca7b78786c91057240d0e2e1bdfb335a68080112640a2d747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e5472616e73666572436f6e747261637412330a1541ab63886b97ccb4cadb942ceb09c3c01a4c6953e812154166583b8482f2462b48f5ba128cf2f46567c0d3111880e1eb1770e6cfcfbdfb33"

    static let liFiRawTransactionHex = "0a02c487220879465709b677160340a8f796c1fa335ab00c081f12ab0c0a31747970652e676f6f676c65617069732e636f6d2f70726f746f636f6c2e54726967676572536d617274436f6e747261637412f50b0a1541ab63886b97ccb4cadb942ceb09c3c01a4c6953e8121541c6594cd50c39ba5f23538fdc3b8492c95edb6fe122c40b3110c7b9000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000460fdea1048bb88b3a27fd39e3b3a671d8d21b7d4218b4ead87b93b5af1f5b3b3bb000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a614f803b6fd780986a42c78ec9c7f77e6ded13c000000000000000000000000d7abce6612079a05e431752cb85bf7010e40fdf50000000000000000000000000000000000000000000000000000000000e172d800000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046e656172000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003444556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000133dbc9f06fa6fd6fafb62b49e4c3d6b41371d0a000000000000000000000000133dbc9f06fa6fd6fafb62b49e4c3d6b41371d0a000000000000000000000000a614f803b6fd780986a42c78ec9c7f77e6ded13c000000000000000000000000a614f803b6fd780986a42c78ec9c7f77e6ded13c0000000000000000000000000000000000000000000000000000000000e4e1c000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000e4332d746b000000000000000000000000a614f803b6fd780986a42c78ec9c7f77e6ded13c00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a7d988115b81dca9d80f0bd14600f01d1ba25cbd000000000000000000000000000000000000000000000000000000000000927c0000000000000000000000009b85558b0c33714164f972e8fa458673de385162000000000000000000000000000000000000000000000000000000000002dc6c00000000000000000000000000000000000000000000000000000000000000000000000000000000d7abce6612079a05e431752cb85bf7010e40fdf5000000000000000000000000512df305b08a9ae47b0030c8a7bbafb7f45cd2f1e963f0caeea140eb466bf21b86869638c37fe88fd723636ef5b425707a7d22f3000000000000000000000000000000000000000000000000000000006a6c7eae0000000000000000000000000000000000000000000000000000000000d518d2000000000000000000000000ab63886b97ccb4cadb942ceb09c3c01a4c6953e800000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000413df0ee48f08152975a4643b362a9787d43348c8e2c705176f3adaf4b7dfac5461fdf8b91e709502dd286962c9541100e2cfc13108b86b574961b6792de8ba5361c0000000000000000000000000000000000000000000000000000000000000070a4b293c1fa33900180a3c347"
    // swiftformat:enable wrap
}
