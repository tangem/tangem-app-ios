//
//  YieldModuleUpgradeCalldata.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import TangemFoundation

enum YieldModuleUpgradeCalldata {
    static let yieldSendMethodId = "0x0779afe6"

    static let v3Implementation = "0xaaF16358336a5e292b1D70057f99c3f2e8241C63"
    static let polygonV2Implementation = "0x66084220E3dFdd1D8C8F1F868C103F9418DEce7c"
    static let polygonV1Implementation = "0xC49B1438c8639AB48953e9091E5277D4C65003f0"
    static let unknownImplementation = "0x5555555555555555555555555555555555555555"

    static func wrapping(_ innerCall: String, implementation: String) -> String {
        let inner = innerCall.removeHexPrefix()
        let paddedLength = (inner.count + 63) / 64 * 64

        return upgradeHead(implementation: implementation, offset: 0x40, length: inner.count / 2)
            + inner.padding(toLength: paddedLength, withPad: "0", startingAt: 0)
    }

    static func upgradeHead(implementation: String, offset: Int, length: Int) -> String {
        [UpgradeToAndCallMethod.methodId, word(address: implementation), word(offset), word(length)].joined()
    }

    static func yieldSend(token: String, to recipient: String, amount: Int) -> String {
        [yieldSendMethodId, word(address: token), word(address: recipient), word(amount)].joined()
    }

    private static func word(address: String) -> String {
        String(repeating: "0", count: 24) + address.removeHexPrefix().lowercased()
    }

    private static func word(_ value: Int) -> String {
        let hex = String(value, radix: 16)
        return String(repeating: "0", count: 64 - hex.count) + hex
    }
}
