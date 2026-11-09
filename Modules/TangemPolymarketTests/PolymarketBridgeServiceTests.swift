//
//  PolymarketBridgeServiceTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
import TangemNetworkUtils
@testable import TangemPolymarket

// MARK: - Fixtures

private enum PolymarketDepositFixtures {
    static let validBuilderCode = "0x0000000000000000000000000000000000000000000000000000000000000001"
    static let depositWallet = "0x5a057dc6394196fba51d84457da3fb8fa241fc20"

    static let withdrawRequest = PolymarketDTO.BridgeWithdrawRequest(
        address: "0xdef0",
        toChainId: "137",
        toTokenAddress: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
        recipientAddr: "0xabc1"
    )

    static let withdrawRoute = PolymarketWithdrawRoute(
        destinationChainId: "8453",
        destinationTokenAddress: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
        recipientAddress: "0x1111111111111111111111111111111111111111"
    )
}

// MARK: - Bridge target

@Suite("Polymarket bridge target", .timeLimit(.minutes(1)))
struct PolymarketBridgeTargetTests {
    private let baseURL = URL(string: "https://bridge.polymarket.com")!

    private func target(_ target: PolymarketBridgeTarget.Target) -> PolymarketBridgeTarget {
        PolymarketBridgeTarget(baseURL: baseURL, target: target)
    }

    @Test("Both calls that move money carry the builder code")
    func builderCodeOnMoneyMovingCalls() {
        let funding = target(.fundingAddresses(.init(address: "0xdef0"), builderCode: PolymarketDepositFixtures.validBuilderCode))
        let withdraw = target(.withdrawAddresses(PolymarketDepositFixtures.withdrawRequest, builderCode: PolymarketDepositFixtures.validBuilderCode))

        #expect(funding.headers?["X-Builder-Code"] == PolymarketDepositFixtures.validBuilderCode)
        #expect(withdraw.headers?["X-Builder-Code"] == PolymarketDepositFixtures.validBuilderCode)
    }

    @Test("supported-assets carries no headers at all, so it cannot take a builder code")
    func supportedAssetsHasNoHeaders() {
        #expect(target(.supportedAssets).headers == nil)
    }
}

// MARK: - Bridge service

@Suite("Polymarket bridge service", .timeLimit(.minutes(1)))
struct PolymarketBridgeServiceTests {
    @Test("A withdrawal asks the bridge for the route's chain, token and recipient, from the deposit wallet")
    func withdrawalSendsTheRoute() async throws {
        let baseURL = PolymarketStubURLProtocol.makeBaseURL(
            answering: .init(body: #"{"address":{"evm":"0x2222222222222222222222222222222222222222"}}"#)
        )
        let service = CommonPolymarketBridgeService(
            provider: TangemProvider(configuration: PolymarketStubURLProtocol.makeConfiguration()),
            baseURL: baseURL
        )

        let addresses = try await service.withdrawAddresses(
            forDepositWallet: PolymarketDepositFixtures.depositWallet,
            route: PolymarketDepositFixtures.withdrawRoute,
            builderCode: PolymarketDepositFixtures.validBuilderCode
        )

        let requests = PolymarketStubURLProtocol.sentRequests(to: baseURL)
        #expect(requests.count == 1)

        let sent = try #require(requests.first)
        let body = try #require(try JSONSerialization.jsonObject(with: sent.body) as? [String: String])

        #expect(sent.method == "POST")
        #expect(sent.url?.path == "/withdraw")
        #expect(sent.header("X-Builder-Code") == PolymarketDepositFixtures.validBuilderCode)
        #expect(body == [
            "address": PolymarketDepositFixtures.depositWallet,
            "toChainId": "8453",
            "toTokenAddress": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
            "recipientAddr": "0x1111111111111111111111111111111111111111",
        ])
        #expect(addresses.address(for: .evm) == "0x2222222222222222222222222222222222222222")
    }
}
