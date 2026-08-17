//
//  ScaledUIAmountAnswerTests.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import BlockchainSdk

/// Responses are modelled on what mainnet providers return for the Token-2022 mints of Apple xStock (scaled) and
/// PayPal USD (not scaled).
struct ScaledUIAmountAnswerTests {
    private let effectiveTimestamp: Int64 = 1_778_293_800
    private let currentMultiplier = "1.002018559465695"
    private let scheduledMultiplier = "1.0026642075893797"

    @Test
    func declaredMultiplierIsRead() throws {
        let answer = try answer(
            from: scaledMint(),
            transactionDate: Date(timeIntervalSince1970: TimeInterval(effectiveTimestamp - 1))
        )

        #expect(answer == .multiplier(Decimal(stringValue: currentMultiplier)!))
    }

    @Test
    func scheduledMultiplierIsReadOnceEffective() throws {
        let answer = try answer(
            from: scaledMint(),
            transactionDate: Date(timeIntervalSince1970: TimeInterval(effectiveTimestamp))
        )

        #expect(answer == .multiplier(Decimal(stringValue: scheduledMultiplier)!))
    }

    @Test(arguments: [
        #"[{"extension": "transferFeeConfig", "state": {}}, {"extension": "tokenMetadata", "state": {}}]"#,
        "[]",
    ])
    func mintWithoutTheExtensionReportsNoScaling(extensions: String) throws {
        #expect(try answer(from: mint(extensions: extensions)) == .noScaling)
    }

    /// The heart of it: a provider whose parser predates the extension hides it behind a placeholder name, and taking
    /// that for `noScaling` would both skip the division and — since it then contradicts an up-to-date provider —
    /// deny every transfer of a scaled mint.
    @Test(arguments: ["unparseableExtension", "unparsableExtension"])
    func unnamedExtensionSettlesNothing(placeholder: String) throws {
        let extensions = """
        [
          {"extension": "metadataPointer", "state": {}},
          {"extension": "\(placeholder)"}
        ]
        """

        #expect(try answer(from: mint(extensions: extensions)) == .unknown)
    }

    @Test
    func missingAccountSettlesNothing() throws {
        #expect(try answer(from: #"{"value": null}"#) == .unknown)
    }

    @Test
    func extensionWithoutStateSettlesNothing() throws {
        let extensions = #"[{"extension": "scaledUiAmountConfig", "state": null}]"#

        #expect(try answer(from: mint(extensions: extensions)) == .unknown)
    }

    @Test(arguments: [
        #"{"multiplier": "not a number", "newMultiplier": "not a number", "newMultiplierEffectiveTimestamp": null}"#,
        #"{"multiplier": null, "newMultiplier": null, "newMultiplierEffectiveTimestamp": null}"#,
        "{}",
    ])
    func unreadableMultiplierSettlesNothing(state: String) throws {
        let extensions = """
        [{"extension": "scaledUiAmountConfig", "state": \(state)}]
        """

        #expect(try answer(from: mint(extensions: extensions)) == .unknown)
    }

    // MARK: - Helpers

    private func answer(
        from json: String,
        transactionDate: Date = Date(timeIntervalSince1970: 0)
    ) throws -> ScaledUIAmount.Answer {
        let accountInfo = try JSONDecoder().decode(
            SolanaScaledUiAmountDTO.GetAccountInfoResult.self,
            from: Data(json.utf8)
        )

        return ScaledUIAmount.Answer(accountInfo: accountInfo, transactionDate: transactionDate)
    }

    private func scaledMint() -> String {
        mint(extensions: """
        [
          {"extension": "metadataPointer", "state": {}},
          {"extension": "scaledUiAmountConfig",
           "state": {"authority": "S7vYFFWH6BjJyEsdrPQpqpYTqLTrPRK6KW3VwsJuRaS",
                     "multiplier": "\(currentMultiplier)",
                     "newMultiplier": "\(scheduledMultiplier)",
                     "newMultiplierEffectiveTimestamp": \(effectiveTimestamp)}}
        ]
        """)
    }

    private func mint(extensions: String) -> String {
        """
        {
          "value": {
            "data": {
              "parsed": {
                "info": {"decimals": 8, "extensions": \(extensions)},
                "type": "mint"
              },
              "program": "spl-token-2022"
            },
            "owner": "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
          }
        }
        """
    }
}
