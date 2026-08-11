//
//  TransferERC20TokenMethodDecodingRejectionTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk

extension SmartContractMethodTests {
    struct TransferERC20TokenMethodDecodingRejectionTestCase {
        let name: String
        let calldata: Data

        private init(name: String, hex: [String]) {
            self.name = name
            calldata = Data(hex: hex.joined())
        }

        static let approveInsteadOfTransfer: Self = .init(
            name: "approve instead of transfer",
            hex: [
                "095ea7b3",
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
                "00000000000000000000000000000000000000000000000000000000000f4240",
            ]
        )

        static let empty: Self = .init(name: "empty calldata", hex: [])

        static let methodIdOnly: Self = .init(name: "method id without arguments", hex: ["a9059cbb"])

        static let truncatedArguments: Self = .init(
            name: "amount slot one byte short",
            hex: [
                "a9059cbb",
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
                "00000000000000000000000000000000000000000000000000000000000f42",
            ]
        )

        static let trailingBytes: Self = .init(
            name: "extra slot after the arguments",
            hex: [
                "a9059cbb",
                "00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c67",
                "00000000000000000000000000000000000000000000000000000000000f4240",
                "0000000000000000000000000000000000000000000000000000000000000001",
            ]
        )

        static let dirtyAddressSlot: Self = .init(
            name: "non-zero padding in the address slot",
            hex: [
                "a9059cbb",
                "00000000000000000000002290e4d59c8583e37426b37d1d7394b6008a987c67",
                "00000000000000000000000000000000000000000000000000000000000f4240",
            ]
        )
    }
}

// MARK: - CustomStringConvertible

extension SmartContractMethodTests.TransferERC20TokenMethodDecodingRejectionTestCase: CustomStringConvertible {
    var description: String { name }
}
