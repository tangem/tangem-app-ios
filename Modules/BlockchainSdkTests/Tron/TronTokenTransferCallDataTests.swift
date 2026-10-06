//
//  TronTokenTransferCallDataTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

private let recipient = "TQrY8tryqsYVCYS3MFbtffiPp2ccyn4STm"
private let recipientBody = "a346f2bd7d43a5d90b7c57a18196be96b2840e61"
private let amount = String(repeating: "0", count: 59) + "f4240"

struct TronTokenTransferCallDataTests {
    @Test("A recipient padded with the Tron prefix decodes", arguments: ["", "0x"])
    func decodesRecipientPaddedWithThePrefix(hexPrefix: String) throws {
        let calldata = hexPrefix + "a9059cbb" + String(repeating: "00", count: 11) + "41" + recipientBody + amount

        let transfer = try #require(TronTokenTransferCallData(calldata: calldata))

        #expect(transfer.recipient == recipient)
        #expect(transfer.amount == 1_000_000)
    }

    @Test("A recipient padded the ERC20 way, without the Tron prefix, decodes")
    func decodesRecipientPaddedWithoutThePrefix() throws {
        let calldata = "a9059cbb" + String(repeating: "00", count: 12) + recipientBody + amount

        let transfer = try #require(TronTokenTransferCallData(calldata: calldata))

        #expect(transfer.recipient == recipient)
        #expect(transfer.amount == 1_000_000)
    }

    @Test("A call to any other method doesn't decode")
    func rejectsAnotherMethod() {
        let approveCalldata = "095ea7b3" + String(repeating: "00", count: 11) + "41" + recipientBody + amount

        #expect(TronTokenTransferCallData(calldata: approveCalldata) == nil)
    }

    @Test(
        "A recipient slot with a dirty padding or an unknown address prefix doesn't decode",
        arguments: [
            "01" + String(repeating: "00", count: 10) + "41",
            String(repeating: "00", count: 11) + "42",
        ]
    )
    func rejectsDirtyRecipientSlot(slotHead: String) {
        let calldata = "a9059cbb" + slotHead + recipientBody + amount

        #expect(TronTokenTransferCallData(calldata: calldata) == nil)
    }

    @Test(
        "Call data of any other length doesn't decode",
        arguments: [
            "a9059cbb" + recipientBody + amount,
            "a9059cbb" + String(repeating: "00", count: 11) + "41" + recipientBody,
            "a9059cbb" + String(repeating: "00", count: 11) + "41" + recipientBody + amount + "00",
            "a9059cbb",
            "",
        ]
    )
    func rejectsAnyOtherLength(calldata: String) {
        #expect(TronTokenTransferCallData(calldata: calldata) == nil)
    }
}
