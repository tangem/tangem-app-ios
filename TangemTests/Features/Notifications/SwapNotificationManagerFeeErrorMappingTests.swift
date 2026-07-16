//
//  SwapNotificationManagerFeeErrorMappingTests.swift
//  TangemTests
//
//  Covers CommonSwapNotificationManager.mapToFeeErrorEvents ([REDACTED_INFO]): a failed fee load reaches the
//  swap flow as a `.requiredRefresh` error, and the two TokenFeeProviderError fee-coverage cases must be
//  routed to the insufficient-fee notifications instead of collapsing into the generic error. Every other
//  error keeps falling through to the generic error (nil).
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("CommonSwapNotificationManager — fee-load error → notification mapping")
struct SwapNotificationManagerFeeErrorMappingTests {
    /// A token on Polygon; its fee is normally paid in the native coin (POL).
    private let tokenItem: TokenItem = .token(
        .init(name: "USD Coin", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6),
        .init(.polygon(testnet: false), derivationPath: nil)
    )

    @Test("No native coin for the fee → the native-coin insufficient-fee notification")
    func notEnoughBalanceForFeeMapsToNotEnoughFeeForTokenTx() throws {
        let sut = CommonSwapNotificationManager()

        let event = try #require(sut.mapToFeeErrorEvent(occurredError: TokenFeeProviderError.notEnoughBalanceForFee, tokenItem: tokenItem))

        guard case .notEnoughFeeForTokenTx(_, let mainTokenSymbol, _, _) = event else {
            Issue.record("Expected .notEnoughFeeForTokenTx, got \(event)")
            return
        }

        #expect(mainTokenSymbol == tokenItem.blockchain.currencySymbol)
    }

    @Test("Gasless token balance below threshold → the token-denominated insufficient-fee notification")
    func notEnoughGaslessFeeBalanceMapsToValidationErrorEvent() throws {
        let sut = CommonSwapNotificationManager()

        let event = try #require(sut.mapToFeeErrorEvent(occurredError: TokenFeeProviderError.notEnoughGaslessFeeBalance, tokenItem: tokenItem))

        guard case .validationErrorEvent = event else {
            Issue.record("Expected .validationErrorEvent, got \(event)")
            return
        }
    }

    @Test("Unrelated fee-provider errors fall through to the generic error notification")
    func unrelatedErrorReturnsNil() {
        let sut = CommonSwapNotificationManager()

        #expect(sut.mapToFeeErrorEvent(occurredError: TokenFeeProviderError.providerUnavailable, tokenItem: tokenItem) == nil)
    }
}
