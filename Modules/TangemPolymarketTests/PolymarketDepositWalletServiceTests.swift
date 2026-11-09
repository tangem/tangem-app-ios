//
//  PolymarketDepositWalletServiceTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("PolymarketDepositWalletStatus", .timeLimit(.minutes(1)))
struct PolymarketDepositWalletStatusTests {
    private let decoder = JSONDecoder()

    @Test("A state added later decodes as unknown and keeps the client polling")
    func unknownStatusKeepsPolling() throws {
        let decoded = try decoder.decode(PolymarketDepositWalletStatus.self, from: Data("\"SOMETHING_NEW\"".utf8))

        #expect(decoded == .unknown)
        #expect(decoded.isInProgress)
        #expect(!decoded.isFailed)
    }

    @Test("Only the two submitted states are in progress, so a deployed wallet still waits for its approvals")
    func inProgressStates() {
        #expect(PolymarketDepositWalletStatus.deploymentInProgress.isInProgress)
        #expect(PolymarketDepositWalletStatus.approvalsInProgress.isInProgress)
        #expect(!PolymarketDepositWalletStatus.deployed.isInProgress)
        #expect(!PolymarketDepositWalletStatus.readyToTrade.isInProgress)
        #expect(PolymarketDepositWalletStatus.deployed != .readyToTrade)
    }
}

@Suite("PolymarketWalletError mapping", .timeLimit(.minutes(1)))
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

// MARK: - Record verification

@Suite("Deposit wallet record verification", .timeLimit(.minutes(1)))
struct PolymarketDepositWalletRecordVerificationTests {
    private let derived = "0xAbCdEf0000000000000000000000000000000002"

    @Test("A record naming the derived wallet passes")
    func matchingRecordPasses() throws {
        let record = PolymarketDepositWallet(address: derived, status: .readyToTrade)

        try record.ensureMatches(derived: derived)
    }

    @Test("A record the backend stores in lowercase passes against the checksummed derivation")
    func lowercaseRecordPasses() throws {
        let record = PolymarketDepositWallet(address: derived.lowercased(), status: .readyToTrade)

        try record.ensureMatches(derived: derived)
    }

    @Test("A record naming another wallet is rejected")
    func foreignRecordIsRejected() {
        let record = PolymarketDepositWallet(address: "0xAbCdEf0000000000000000000000000000000003", status: .readyToTrade)

        do {
            try record.ensureMatches(derived: derived)
            Issue.record("A foreign record passed verification")
        } catch PolymarketOnboardingError.addressMismatch {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("A record without an address passes without any comparison, so every caller has to guard it itself")
    func missingAddressIsNotCompared() throws {
        let record = PolymarketDepositWallet(address: nil, status: .readyToTrade)

        try record.ensureMatches(derived: derived)
    }
}
