//
//  BaseTestCase+Polymarket.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

extension BaseTestCase {
    @discardableResult
    func launchPolymarketWithHotWallet(scenarios: [ScenarioConfig] = []) -> MainScreen {
        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: scenarios,
            extraLaunchArguments: [PolymarketUITestsConstants.experimentArgument]
        )

        return importHotWallet()
    }

    func polymarketFullAccessScenarios() -> [ScenarioConfig] {
        [
            ScenarioConfig(name: PolymarketUITestsConstants.Scenario.feed, initialState: PolymarketUITestsConstants.State.feedLoaded),
            ScenarioConfig(name: PolymarketUITestsConstants.Scenario.bridge, initialState: PolymarketUITestsConstants.State.available),
            ScenarioConfig(name: PolymarketUITestsConstants.Scenario.userTokens, initialState: PolymarketUITestsConstants.State.polygonUSDCHotWallet),
            ScenarioConfig(name: PolymarketUITestsConstants.Scenario.quotes, initialState: PolymarketUITestsConstants.State.polygonUSDC),
        ]
    }

    func polymarketRequestCount(method: String, path: String) -> Int {
        wireMockClient.requestCountSync(method: method, urlPathPattern: path)
    }

    func waitForPolymarketRequestCount(
        method: String,
        path: String,
        toExceed previousCount: Int,
        timeout: TimeInterval = .networkRequest
    ) {
        XCTContext.runActivity(named: "Wait for \(method) \(path) request") { _ in
            let predicate = NSPredicate { [self] _, _ in
                polymarketRequestCount(method: method, path: path) > previousCount
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: timeout),
                .completed,
                "A \(method) request to \(path) should be sent more than \(previousCount) times"
            )
        }
    }

    func polymarketWalletStatusQueryValues(named name: String) -> [String] {
        wireMockClient
            .findRequestURLsSync(method: "GET", urlPath: PolymarketUITestsConstants.Path.walletStatus)
            .compactMap { URLComponents(string: $0)?.queryItems?.first { $0.name == name }?.value }
    }

    func waitForPolymarketWalletStatusQuery(
        named name: String,
        toExceed previousCount: Int,
        timeout: TimeInterval = .networkRequest
    ) {
        XCTContext.runActivity(named: "Wait for the wallet status requested by '\(name)'") { _ in
            let predicate = NSPredicate { [self] _, _ in
                polymarketWalletStatusQueryValues(named: name).count > previousCount
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: timeout),
                .completed,
                "The wallet status should be requested by '\(name)' more than \(previousCount) times"
            )
        }
    }

    func polymarketRequestBodies(method: String, path: String, after requestsBefore: Int) -> [String] {
        Array(wireMockClient.findRequestBodiesSync(method: method, urlPath: path).dropFirst(requestsBefore))
    }

    func polymarketRequestHeaders(method: String, path: String, after requestsBefore: Int) -> [[String: String]] {
        Array(wireMockClient.findRequestHeadersSync(method: method, urlPath: path).dropFirst(requestsBefore))
    }

    func polymarketRequestTimestamps(method: String, path: String, after requestsBefore: Int) -> [Date] {
        Array(wireMockClient.findRequestTimestampsSync(method: method, urlPattern: path).dropFirst(requestsBefore))
    }

    func assertPolymarketDeployRequestMatchesWallet(requestsBefore: Int) {
        XCTContext.runActivity(named: "Assert the deploy request carries the owner, wallet id and deposit wallet addresses") { _ in
            let bodies = polymarketRequestBodies(method: "POST", path: PolymarketUITestsConstants.Path.deploy, after: requestsBefore)
            XCTAssertEqual(bodies.count, 1, "Exactly one deploy request is expected")

            let body = decodeJSONObject(bodies.first)
            XCTAssertEqual(body[PolymarketUITestsConstants.Field.ownerAddress], PolymarketUITestsConstants.Wallet.ownerAddress)
            XCTAssertEqual(body[PolymarketUITestsConstants.Field.walletId], PolymarketUITestsConstants.Wallet.walletId)
            XCTAssertEqual(body[PolymarketUITestsConstants.Field.depositWalletAddress], PolymarketUITestsConstants.Wallet.depositWallet)
        }
    }

    func assertPolymarketApprovalsRequestMatchesWallet(requestsBefore: Int) {
        XCTContext.runActivity(named: "Assert the approvals request carries the owner and deposit wallet addresses") { _ in
            let bodies = polymarketRequestBodies(method: "POST", path: PolymarketUITestsConstants.Path.approvals, after: requestsBefore)
            XCTAssertEqual(bodies.count, 1, "Exactly one approvals request is expected")

            let body = decodeJSONObject(bodies.first)
            XCTAssertEqual(body[PolymarketUITestsConstants.Field.ownerAddress], PolymarketUITestsConstants.Wallet.ownerAddress)
            XCTAssertEqual(body[PolymarketUITestsConstants.Field.depositWalletAddress], PolymarketUITestsConstants.Wallet.depositWallet)
        }
    }

    func assertPolymarketL1HeadersSent(method: String, path: String, requestsBefore: Int) {
        XCTContext.runActivity(named: "Assert the \(method) \(path) request is signed with the L1 signature") { _ in
            let headers = polymarketRequestHeaders(method: method, path: path, after: requestsBefore).first ?? [:]
            XCTAssertEqual(
                headers[PolymarketUITestsConstants.Header.address]?.lowercased(),
                PolymarketUITestsConstants.Wallet.ownerAddress.lowercased()
            )
            XCTAssertNotNil(
                headers[PolymarketUITestsConstants.Header.signature]?.range(of: PolymarketUITestsConstants.l1SignaturePattern, options: .regularExpression),
                "L1 signature must be a hex string"
            )
            XCTAssertNotNil(
                headers[PolymarketUITestsConstants.Header.timestamp]?.range(of: "^[0-9]+$", options: .regularExpression),
                "L1 timestamp must be numeric"
            )
            XCTAssertNotNil(headers[PolymarketUITestsConstants.Header.nonce], "L1 nonce must be present")
        }
    }

    func assertPolymarketL2CredentialsSent(apiKey: String, balanceRequestsBefore: Int = 0) {
        XCTContext.runActivity(named: "Assert the account requests carry the L2 credentials") { _ in
            let lastBalanceHeaders = { [self] in
                polymarketRequestHeaders(
                    method: "GET",
                    path: PolymarketUITestsConstants.Path.balance,
                    after: balanceRequestsBefore
                ).last ?? [:]
            }
            let predicate = NSPredicate { _, _ in
                lastBalanceHeaders()[PolymarketUITestsConstants.Header.apiKey] == apiKey
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .networkRequest),
                .completed,
                "The balance request should carry the API key \(apiKey)"
            )

            let headers = lastBalanceHeaders()
            XCTAssertEqual(headers[PolymarketUITestsConstants.Header.passphrase], PolymarketUITestsConstants.Wallet.apiPassphrase)
            XCTAssertFalse(headers[PolymarketUITestsConstants.Header.signature].isNilOrEmpty, "L2 signature must be present")
        }
    }

    func assertPolymarketRequestOrder(
        first: (method: String, path: String, requestsBefore: Int),
        second: (method: String, path: String, requestsBefore: Int)
    ) {
        XCTContext.runActivity(named: "Assert \(first.method) \(first.path) precedes \(second.method) \(second.path)") { _ in
            let firstDate = polymarketRequestTimestamps(method: first.method, path: first.path, after: first.requestsBefore).first
            let secondDate = polymarketRequestTimestamps(method: second.method, path: second.path, after: second.requestsBefore).first

            guard let firstDate, let secondDate else {
                XCTFail("Both requests should be journalled")
                return
            }

            XCTAssertLessThanOrEqual(firstDate, secondDate)
        }
    }

    private func decodeJSONObject(_ body: String?) -> [String: String] {
        guard let data = body?.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Request body should be a JSON object")
            return [:]
        }

        return object.compactMapValues { $0 as? String }
    }
}

private extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

enum PolymarketUITestsConstants {
    static let experimentArgument = "-uitest-experiment-twi_1576_polymarket-on"
    static let l1SignaturePattern = "^0x[0-9a-fA-F]{130}$"
    static let minimumStatusPolls = 4

    enum Query {
        static let walletId = "walletId"
        static let ownerAddress = "ownerAddress"
    }

    enum Scenario {
        static let wallet = "polymarket_wallet"
        static let ownerWallet = "polymarket_wallet_ios"
        static let geoblock = "polymarket_geoblock"
        static let credentials = "polymarket_clob_credentials"
        static let balance = "polymarket_clob_balance"
        static let bridge = "polymarket_bridge"
        static let feed = "polymarket_feed"
        static let userTokens = "user_tokens_api"
        static let quotes = "quotes_api"
    }

    enum Path {
        static let walletStatus = "/api/predictions/v1/wallet"
        static let deploy = "/api/predictions/v1/wallet/deploy"
        static let approvals = "/api/predictions/v1/wallet/approvals"
        static let deriveKey = "/clob.polymarket.com/auth/derive-api-key"
        static let createKey = "/clob.polymarket.com/auth/api-key"
        static let balance = "/clob.polymarket.com/balance-allowance"
        static let geoblock = "/polymarket.com/api/geoblock"
        static let bridgeDeposit = "/bridge.polymarket.com/deposit"
    }

    enum Wallet {
        static let walletId = "916A3887E37D720A7D8FBC8CD08EF4B1793E40B70C30D81259BB6E858B9FBA24"
        static let ownerAddress = "0x1AfaF0481dCF5D965BC1034115f44915Bf70F589"
        static let depositWallet = "0xD755B16aF3C08771CFc45f73A6fB84dDc6b3528A"
        static let derivedApiKey = "00000000-0000-4000-8000-000000000001"
        static let createdApiKey = "00000000-0000-4000-8000-000000000002"
        static let apiPassphrase = "mock-polymarket-passphrase"
    }

    enum Field {
        static let ownerAddress = "ownerAddress"
        static let walletId = "walletId"
        static let depositWalletAddress = "depositWalletAddress"
    }

    enum Header {
        static let address = "poly_address"
        static let signature = "poly_signature"
        static let timestamp = "poly_timestamp"
        static let nonce = "poly_nonce"
        static let apiKey = "poly_api_key"
        static let passphrase = "poly_passphrase"
    }

    enum State {
        static let readyToTrade = "ReadyToTrade"
        static let deployed = "Deployed"
        static let deploymentInProgress = "DeploymentInProgress1"
        static let deploymentFailed = "DeploymentFailed"
        static let notExisting = "NotExisting"
        static let expired = "Expired"
        static let blocked = "Blocked"
        static let available = "Available"
        static let feedLoaded = "FeedLoaded"
        static let polygonUSDCHotWallet = "PolygonUSDCHotWallet"
        static let polygonUSDC = "PolygonUSDC"
    }
}
