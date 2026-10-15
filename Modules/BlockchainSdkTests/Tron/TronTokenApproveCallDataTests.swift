//
//  TronTokenApproveCallDataTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

private let spender = "TQrY8tryqsYVCYS3MFbtffiPp2ccyn4STm"
private let spenderBody = "a346f2bd7d43a5d90b7c57a18196be96b2840e61"
private let amount = String(repeating: "0", count: 59) + "f4240"

struct TronTokenApproveCallDataTests {
    @Test("A spender padded with the Tron prefix decodes", arguments: ["", "0x"])
    func decodesSpenderPaddedWithThePrefix(hexPrefix: String) throws {
        let calldata = hexPrefix + "095ea7b3" + String(repeating: "00", count: 11) + "41" + spenderBody + amount

        let approve = try #require(TronTokenApproveCallData(calldata: calldata))

        #expect(approve.spender == spender)
        #expect(approve.amount == 1_000_000)
    }

    @Test("A spender padded the ERC20 way, without the Tron prefix, decodes")
    func decodesSpenderPaddedWithoutThePrefix() throws {
        let calldata = "095ea7b3" + String(repeating: "00", count: 12) + spenderBody + amount

        let approve = try #require(TronTokenApproveCallData(calldata: calldata))

        #expect(approve.spender == spender)
        #expect(approve.amount == 1_000_000)
    }

    @Test("A call to any other method doesn't decode")
    func rejectsAnotherMethod() {
        let transferCalldata = "a9059cbb" + String(repeating: "00", count: 11) + "41" + spenderBody + amount

        #expect(TronTokenApproveCallData(calldata: transferCalldata) == nil)
    }

    @Test(
        "A spender slot with a dirty padding or an unknown address prefix doesn't decode",
        arguments: [
            "01" + String(repeating: "00", count: 10) + "41",
            String(repeating: "00", count: 11) + "42",
        ]
    )
    func rejectsDirtySpenderSlot(slotHead: String) {
        let calldata = "095ea7b3" + slotHead + spenderBody + amount

        #expect(TronTokenApproveCallData(calldata: calldata) == nil)
    }

    @Test(
        "Call data of any other length doesn't decode",
        arguments: [
            "095ea7b3" + spenderBody + amount,
            "095ea7b3" + String(repeating: "00", count: 11) + "41" + spenderBody,
            "095ea7b3" + String(repeating: "00", count: 11) + "41" + spenderBody + amount + "00",
            "095ea7b3",
            "",
        ]
    )
    func rejectsAnyOtherLength(calldata: String) {
        #expect(TronTokenApproveCallData(calldata: calldata) == nil)
    }
}
