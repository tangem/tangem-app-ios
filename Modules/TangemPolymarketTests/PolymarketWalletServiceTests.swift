//
//  PolymarketWalletServiceTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("PolymarketWalletStatus")
struct PolymarketWalletStatusTests {
    private let decoder = JSONDecoder()

    @Test(
        "The seven contract states decode by their backend representation",
        arguments: [
            ("NOT_CREATED", PolymarketWalletStatus.notCreated),
            ("DEPLOYMENT_IN_PROGRESS", .deploymentInProgress),
            ("DEPLOYMENT_FAILED", .deploymentFailed),
            ("DEPLOYED", .deployed),
            ("APPROVALS_IN_PROGRESS", .approvalsInProgress),
            ("APPROVALS_FAILED", .approvalsFailed),
            ("READY_TO_TRADE", .readyToTrade),
        ]
    )
    func knownStatusDecodes(rawValue: String, expected: PolymarketWalletStatus) throws {
        let decoded = try decoder.decode(PolymarketWalletStatus.self, from: Data("\"\(rawValue)\"".utf8))

        #expect(decoded == expected)
    }

    @Test("A state added later decodes as unknown and keeps the client polling")
    func unknownStatusKeepsPolling() throws {
        let decoded = try decoder.decode(PolymarketWalletStatus.self, from: Data("\"SOMETHING_NEW\"".utf8))

        #expect(decoded == .unknown)
        #expect(decoded.isInProgress)
        #expect(!decoded.isFailed)
    }

    @Test("Only the two submitted states are in progress")
    func inProgressStates() {
        #expect(PolymarketWalletStatus.deploymentInProgress.isInProgress)
        #expect(PolymarketWalletStatus.approvalsInProgress.isInProgress)
        #expect(!PolymarketWalletStatus.deployed.isInProgress)
        #expect(!PolymarketWalletStatus.readyToTrade.isInProgress)
    }

    @Test("A deployed wallet is not a ready one, so approvals stay observable from the status")
    func deployedIsNotReadyToTrade() {
        #expect(PolymarketWalletStatus.deployed != .readyToTrade)
    }
}

@Suite("PolymarketWalletState decoding")
struct PolymarketWalletStateDecodingTests {
    private let decoder = JSONDecoder()

    @Test("An owner without a record decodes with a null address")
    func noRecordDecodes() throws {
        let body = Data(#"{ "depositWalletAddress": null, "status": "NOT_CREATED" }"#.utf8)

        let decoded = try decoder.decode(PolymarketDTO.WalletStatusResponse.self, from: body)

        #expect(decoded.depositWalletAddress == nil)
        #expect(decoded.status == .notCreated)
    }

    @Test("A stored record decodes with its lowercase address")
    func storedRecordDecodes() throws {
        let body = Data(#"{ "depositWalletAddress": "0xdef0000000000000000000000000000000000002", "status": "DEPLOYMENT_IN_PROGRESS" }"#.utf8)

        let decoded = try decoder.decode(PolymarketDTO.WalletStatusResponse.self, from: body)

        #expect(decoded.depositWalletAddress == "0xdef0000000000000000000000000000000000002")
        #expect(decoded.status == .deploymentInProgress)
    }
}

@Suite("PolymarketWalletError mapping")
struct PolymarketWalletErrorTests {
    @Test("Each documented status code becomes the failure the caller has to act on differently")
    func statusCodesMapToTypedErrors() {
        #expect(mapped(400, detail: "Invalid address: nope").isBadRequest)
        #expect(mapped(401).isUnauthorized)
        #expect(mapped(409, detail: "Deposit wallet is not deployed yet").isConflict)
        #expect(mapped(422, detail: "deadline is too soon").isRelayerRejected)
        #expect(mapped(502, detail: "Polymarket relayer is unavailable").isUpstreamUnavailable)
    }

    @Test("The relayer's own message survives, because the retry decision is made from it")
    func relayerDetailSurvives() {
        guard case .relayerRejected(let detail) = mapped(422, detail: "nonce reused") else {
            Issue.record("Expected .relayerRejected")
            return
        }

        #expect(detail == "nonce reused")
    }

    @Test("Cancellation is its own failure, so a cancelled poll is not reported as a network problem")
    func cancellationIsNotAFailure() {
        #expect(PolymarketWalletError.cancelled.isCancelled)
        #expect(!PolymarketWalletError.cancelled.isUpstreamUnavailable)
    }

    @Test("An undocumented code is not silently reshaped into a known failure")
    func unexpectedCodeStaysOther() {
        #expect(mapped(418).isOther)
    }

    private func mapped(_ statusCode: Int, detail: String? = nil) -> PolymarketWalletError {
        let problemDetail = PolymarketProblemDetail(
            type: nil,
            title: nil,
            status: statusCode,
            detail: detail,
            instance: nil
        )

        return PolymarketWalletError(apiError: .http(statusCode: statusCode, problemDetail: problemDetail))
    }
}
