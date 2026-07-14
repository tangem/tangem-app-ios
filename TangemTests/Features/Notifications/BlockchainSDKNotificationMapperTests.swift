//
//  BlockchainSDKNotificationMapperTests.swift
//  TangemTests
//
//  Covers mapToInsufficientBalanceForFeeEvent() — the event built for [REDACTED_INFO] when the fee
//  couldn't be loaded because there's no native coin to pay it (so there's no ValidationError/Fee
//  to derive the notification from).
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("BlockchainSDKNotificationMapper — mapToInsufficientBalanceForFeeEvent")
struct BlockchainSDKNotificationMapperTests {
    private let ethTokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    private let usdtTokenItem: TokenItem = .token(
        .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    @Test("Token send builds the native-coin insufficient-balance-for-fee event")
    func tokenSendBuildsInsufficientBalanceForFee() throws {
        let mapper = BlockchainSDKNotificationMapper(tokenItem: usdtTokenItem)

        let event = mapper.mapToInsufficientBalanceForFeeEvent()

        guard case .insufficientBalanceForFee(let configuration) = event else {
            Issue.record("Expected .insufficientBalanceForFee, got \(event)")
            return
        }

        // The token being sent.
        #expect(configuration.transactionAmountTypeName == usdtTokenItem.name)
        #expect(configuration.amountCurrencySymbol == usdtTokenItem.currencySymbol)
        // The fee is paid in the network's native coin, not the token.
        #expect(configuration.feeAmountTypeName == usdtTokenItem.blockchain.coinDisplayName)
        #expect(configuration.feeAmountTypeCurrencySymbol == usdtTokenItem.blockchain.currencySymbol)
        #expect(configuration.networkName == usdtTokenItem.networkName)
        // "Go to <coin>" CTA must be offered.
        #expect(configuration.isFeeCurrencyPurchaseAllowed)
    }

    @Test("Coin send degrades to plain insufficient-balance (no fee currency to top up)")
    func coinSendDegradesToInsufficientBalance() {
        let mapper = BlockchainSDKNotificationMapper(tokenItem: ethTokenItem)

        let event = mapper.mapToInsufficientBalanceForFeeEvent()

        guard case .insufficientBalance = event else {
            Issue.record("Expected .insufficientBalance for a coin send, got \(event)")
            return
        }
    }

    @Test("Gasless event uses the token itself as the fee currency")
    func gaslessBuildsInsufficientBalanceForFeeInToken() throws {
        let mapper = BlockchainSDKNotificationMapper(tokenItem: usdtTokenItem)

        let event = mapper.mapToInsufficientGaslessFeeEvent()

        guard case .insufficientBalanceForFee(let configuration) = event else {
            Issue.record("Expected .insufficientBalanceForFee, got \(event)")
            return
        }

        // The gasless fee is paid in the token itself, so the fee currency is the token — not the native coin.
        #expect(configuration.feeAmountTypeName == usdtTokenItem.name)
        #expect(configuration.feeAmountTypeCurrencySymbol == usdtTokenItem.currencySymbol)
        #expect(configuration.transactionAmountTypeName == usdtTokenItem.name)
    }
}
