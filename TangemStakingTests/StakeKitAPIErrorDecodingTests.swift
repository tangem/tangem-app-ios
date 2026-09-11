//
//  StakeKitAPIErrorDecodingTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking

@Suite("StakeKitAPIError")
struct StakeKitAPIErrorDecodingTests {
    typealias SUT = StakeKitAPIError

    @Test("Decodes path as the failing API method")
    func decodesPath() throws {
        let json = """
        {
            "message": "Insufficient balance for gas fees. Reduce stake amount by 0.000005000 SOL to cover transaction costs.",
            "code": 412,
            "path": "/v1/actions/enter/estimate-gas",
            "level": "error"
        }
        """

        let error = try decode(json)

        #expect(error.path == "/v1/actions/enter/estimate-gas")
        #expect(error.code == "412")
        #expect(
            error.message == "Insufficient balance for gas fees. Reduce stake amount by 0.000005000 SOL to cover transaction costs."
        )
    }

    @Test("Decodes the details behind an insufficient gas reserve")
    func decodesInsufficientGasReserveDetails() throws {
        let json = """
        {
            "details": {
                "code": "INSUFFICIENT_GAS_RESERVE",
                "gasTokenSymbol": "SOL",
                "shortfallAmount": "0.000005000"
            }
        }
        """

        let error = try decode(json)

        #expect(error.details?.code == .insufficientGasReserve)
        #expect(error.details?.gasTokenSymbol == "SOL")
        #expect(error.details?.shortfallAmount == "0.000005000")
    }

    @Test(
        "Decodes bodies carrying no usable path",
        arguments: [
            #"{"message": "SolanaTransactionSimulationError", "code": "400"}"#,
            #"{"message": "Bad gateway", "path": 42}"#,
            "{}",
        ]
    )
    func decodesMissingPath(json: String) throws {
        let error = try decode(json)

        #expect(error.path == nil)
    }
}

// MARK: - Helpers

private extension StakeKitAPIErrorDecodingTests {
    func decode(_ json: String) throws -> SUT {
        try JSONDecoder().decode(SUT.self, from: Data(json.utf8))
    }
}
