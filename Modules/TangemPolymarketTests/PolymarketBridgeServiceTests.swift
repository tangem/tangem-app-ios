//
//  PolymarketBridgeServiceTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import TangemPolymarket

// MARK: - Fixtures

private enum PolymarketDepositFixtures {
    static let validBuilderCode = "0x0000000000000000000000000000000000000000000000000000000000000001"
}

// MARK: - Bridge target

@Suite("Polymarket bridge target")
struct PolymarketBridgeTargetTests {
    private let baseURL = URL(string: "https://bridge.polymarket.com")!

    private func target(_ target: PolymarketBridgeTarget.Target) -> PolymarketBridgeTarget {
        PolymarketBridgeTarget(baseURL: baseURL, target: target)
    }

    @Test("Paths and methods")
    func pathsAndMethods() {
        let assets = target(.supportedAssets)
        let funding = target(.fundingAddresses(.init(address: "0xdef0"), builderCode: PolymarketDepositFixtures.validBuilderCode))

        #expect(assets.path == "supported-assets")
        #expect(assets.method == .get)
        #expect(funding.path == "deposit")
        #expect(funding.method == .post)
    }

    @Test("The builder code is attached to the funding call, which is the only one that accepts it")
    func builderCodeOnFundingCall() {
        let funding = target(.fundingAddresses(.init(address: "0xdef0"), builderCode: PolymarketDepositFixtures.validBuilderCode))

        #expect(funding.headers?["X-Builder-Code"] == PolymarketDepositFixtures.validBuilderCode)
    }

    @Test("supported-assets carries no headers at all, so it cannot take a builder code")
    func supportedAssetsHasNoHeaders() {
        #expect(target(.supportedAssets).headers == nil)
    }

    @Test("The funding request carries the deposit wallet in its body")
    func fundingCarriesTheDepositWallet() throws {
        let funding = target(.fundingAddresses(.init(address: "0xdef0"), builderCode: PolymarketDepositFixtures.validBuilderCode))

        guard case .requestJSONEncodable(let encodable) = funding.task else {
            Issue.record("The funding call must carry a JSON body")
            return
        }

        let payload = try #require(encodable as? PolymarketDTO.DepositRequest)
        #expect(payload.address == "0xdef0")
    }

    @Test("supported-assets takes no parameters")
    func supportedAssetsIsPlain() {
        guard case .requestPlain = target(.supportedAssets).task else {
            Issue.record("supported-assets must be a plain request")
            return
        }
    }
}
