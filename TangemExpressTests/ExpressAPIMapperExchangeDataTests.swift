//
//  ExpressAPIMapperExchangeDataTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("Express exchange data mapping — the payout the backend promises must be the one we asked for")
struct ExpressAPIMapperExchangeDataTests {
    @Test("A payout address equal to the requested one, up to case, is accepted")
    func matchingPayoutAddressIsAccepted() throws {
        let mapper = makeMapper(details: makeDetails(payoutAddress: requestedPayoutAddress.lowercased()))

        let data = try mapper.mapToExpressTransactionData(item: makeItem(), request: makeRequest(), response: makeResponse())

        #expect(data.requestId == requestId)
        #expect(data.destinationAddress == payInAddress)
        #expect(data.payInAddress == payInAddress)
    }

    @Test("The applied exchange-data slippage comes back as a fraction")
    func appliedSlippageIsMappedToFraction() throws {
        let mapper = makeMapper(details: makeDetails(payoutAddress: requestedPayoutAddress))

        let data = try mapper.mapToExpressTransactionData(item: makeItem(), request: makeRequest(), response: makeResponse(slippage: 50))

        #expect(data.slippage == Decimal(string: "0.005"))
    }

    @Test("A payout address other than the requested one is refused before any transaction is built")
    func foreignPayoutAddressIsRefused() {
        let mapper = makeMapper(details: makeDetails(payoutAddress: "0x000000000000000000000000000000000000dEaD"))

        do {
            _ = try mapper.mapToExpressTransactionData(item: makeItem(), request: makeRequest(), response: makeResponse())
            Issue.record("A foreign payout address was accepted")
        } catch ExpressAPIMapperError.payoutAddressNotEqual {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("A payout extra id other than the requested one is refused")
    func foreignPayoutExtraIdIsRefused() {
        let mapper = makeMapper(details: makeDetails(payoutExtraId: "another-memo"))

        do {
            _ = try mapper.mapToExpressTransactionData(item: makeItem(), request: makeRequest(toExtraId: "memo"), response: makeResponse())
            Issue.record("A foreign payout extra id was accepted")
        } catch ExpressAPIMapperError.payoutExtraIdNotEqual {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Details answering another request are refused")
    func foreignRequestIdIsRefused() {
        let mapper = makeMapper(details: makeDetails(requestId: "another-request"))

        do {
            _ = try mapper.mapToExpressTransactionData(item: makeItem(), request: makeRequest(), response: makeResponse())
            Issue.record("Details for another request were accepted")
        } catch ExpressAPIMapperError.requestIdNotEqual {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

// MARK: - Fixtures

private extension ExpressAPIMapperExchangeDataTests {
    var requestId: String { "request-1" }
    var requestedPayoutAddress: String { "0xAbCdEf0000000000000000000000000000000001" }
    var payInAddress: String { "0xPayIn" }
    var sourceAddress: String { "0xSource" }

    var sourceCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "0xUSDT", network: "ethereum", decimalCount: 6, symbol: "USDT")
    }

    var destinationCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "0xUSDC", network: "ethereum", decimalCount: 6, symbol: "USDC")
    }

    var coinCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "0x0", network: "ethereum", decimalCount: 18, symbol: "ETH")
    }

    func makeMapper(details: DecodedTransactionDetails) -> ExpressAPIMapper {
        ExpressAPIMapper(
            exchangeDataDecoder: CannedExchangeDataDecoderStub(details: details),
            featureFlags: ExpressFeatureFlags()
        )
    }

    func makeDetails(
        requestId: String? = nil,
        payoutAddress: String? = nil,
        payoutExtraId: String? = nil
    ) -> DecodedTransactionDetails {
        DecodedTransactionDetails(
            requestId: requestId ?? self.requestId,
            txType: .swap,
            txFrom: sourceAddress,
            txTo: payInAddress,
            txExtraId: nil,
            txData: "0xabcdef",
            txValue: nil,
            otherNativeFee: nil,
            gas: nil,
            externalTxId: nil,
            externalTxUrl: nil,
            payoutAddress: payoutAddress ?? requestedPayoutAddress,
            payoutExtraId: payoutExtraId
        )
    }

    func makeRequest(toExtraId: String? = nil) -> ExpressDTO.Swap.ExchangeData.Request {
        ExpressDTO.Swap.ExchangeData.Request(
            requestId: requestId,
            quoteId: nil,
            fromAddress: sourceAddress,
            fromContractAddress: sourceCurrency.contractAddress,
            fromNetwork: sourceCurrency.network,
            toContractAddress: destinationCurrency.contractAddress,
            toNetwork: destinationCurrency.network,
            toDecimals: destinationCurrency.decimalCount,
            fromAmount: "1000000",
            toAmount: nil,
            fromDecimals: sourceCurrency.decimalCount,
            providerId: "provider",
            rateType: .float,
            toAddress: requestedPayoutAddress,
            toExtraId: toExtraId,
            refundAddress: sourceAddress,
            refundExtraId: nil,
            partnerOperationType: ExpressOperationType.swap.rawValue,
            slippage: nil
        )
    }

    func makeResponse(slippage: Decimal? = nil) -> ExpressDTO.Swap.ExchangeData.Response {
        ExpressDTO.Swap.ExchangeData.Response(
            txId: "tx-1",
            fromAmount: "1000000",
            fromDecimals: 6,
            toAmount: "990000",
            toDecimals: 6,
            txDetailsJson: "{}",
            signature: "",
            payTill: nil,
            slippage: slippage
        )
    }

    func makeItem() -> ExpressSwappableDataItem {
        ExpressSwappableDataItem(
            source: .init(
                address: sourceAddress,
                yieldContractAddress: nil,
                currency: sourceCurrency,
                coinCurrency: coinCurrency,
                amountScale: nil
            ),
            destination: .init(address: requestedPayoutAddress, currency: destinationCurrency, extraId: nil),
            amountType: .from(1),
            rateType: .float,
            providerInfo: .init(id: "provider", type: .dex),
            operationType: .swap,
            quoteId: nil,
            slippage: nil
        )
    }
}

// MARK: - Doubles

private struct CannedExchangeDataDecoderStub: ExpressExchangeDataDecoder {
    let details: DecodedTransactionDetails

    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        guard let decoded = details as? T else {
            throw DecoderStubError.unexpectedType
        }

        return decoded
    }
}

private enum DecoderStubError: Error {
    case unexpectedType
}
