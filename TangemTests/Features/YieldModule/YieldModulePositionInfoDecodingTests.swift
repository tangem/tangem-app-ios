//
//  YieldModulePositionInfoDecodingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Yield token info decoding")
struct YieldModulePositionInfoDecodingTests {
    @Test("The token info the backend returns today decodes, with decimal and exponent amounts and no user fields")
    func currentBackendResponse() throws {
        let info = try JSONDecoder().decode(YieldModuleDTO.Response.PositionInfo.self, from: Data(Self.wethResponse.utf8))

        #expect(info.apy == Decimal(147) / 100)
    }

    @Test("Empty fields other than the rate don't stop the rate from decoding")
    func emptyOtherFieldsKeepRate() throws {
        let response = Self.wethResponse
            .replacingOccurrences(of: "\"maxFeeNative\":\"0.0024\"", with: "\"maxFeeNative\":null")
            .replacingOccurrences(of: "\"isActive\":false", with: "\"isActive\":null")

        let info = try JSONDecoder().decode(YieldModuleDTO.Response.PositionInfo.self, from: Data(response.utf8))

        #expect(info.apy == Decimal(147) / 100)
    }

    @Test("The token info rate is a fraction, like the markets rate")
    func rateIsFraction() throws {
        let dto = try JSONDecoder().decode(YieldModuleDTO.Response.PositionInfo.self, from: Data(Self.wethResponse.utf8))

        let info = YieldModuleTokenInfo(dto: dto)

        #expect(info.apy == Decimal(147) / 10000)
    }

    @Test("A response without a rate is rejected")
    func missingRateIsRejected() {
        let response = Self.wethResponse.replacingOccurrences(of: "\"apy\":1.47,", with: "")

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(YieldModuleDTO.Response.PositionInfo.self, from: Data(response.utf8))
        }
    }
}

// MARK: - Fixtures

private extension YieldModulePositionInfoDecodingTests {
    static let wethResponse = """
    {"tokenAddress":"0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2","tokenSymbol":"WETH","tokenName":"Wrapped Ether",\
    "chainId":1,"chain":"Ethereum","apy":1.47,"ltv":81,"totalSupplied":"2108188.35078085073081884",\
    "totalBorrowed":"1760805.42765890170218209","liquidityRate":"1.465109737654268e+25",\
    "borrowRate":"2.0698718541297168e+25","utilizationRate":83.52,"liquidationThreshold":84,"supplyCap":"2700000",\
    "decimals":18,"maxFeeNative":"0.0024","maxFeeUSD":"7.68","isActive":false,"isForEarn":false}
    """
}
