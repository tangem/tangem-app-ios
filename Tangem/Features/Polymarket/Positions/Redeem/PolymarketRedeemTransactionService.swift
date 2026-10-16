//
//  PolymarketRedeemTransactionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPolymarket

actor PolymarketRedeemTransactionService {
    private let redeemService: PolymarketRedeemService
    private let relayerService: PolymarketRelayerService
    private let depositWalletResolver: PolymarketDepositWalletResolver
    private let signer: PolymarketBatchSigning
    private let serverClock: PolymarketServerClock
    private let pollDelayProvider: PollDelayProvider

    private var isClaimInProgress = false

    init(
        redeemService: PolymarketRedeemService,
        relayerService: PolymarketRelayerService,
        depositWalletResolver: PolymarketDepositWalletResolver,
        signer: PolymarketBatchSigning,
        serverClock: PolymarketServerClock,
        pollDelayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.redeemService = redeemService
        self.relayerService = relayerService
        self.depositWalletResolver = depositWalletResolver
        self.signer = signer
        self.serverClock = serverClock
        self.pollDelayProvider = pollDelayProvider
    }
}

// MARK: - PolymarketRedeeming protocol conformance

extension PolymarketRedeemTransactionService: PolymarketRedeeming {
    func claim(position: PolymarketPosition) async throws -> PolymarketRedeemRecord {
        do {
            return try await performClaim(PolymarketRedeemCallRequest(position: position))
        } catch {
            throw presentable(error)
        }
    }
}

// MARK: - Private implementation

private extension PolymarketRedeemTransactionService {
    func performClaim(_ request: PolymarketRedeemCallRequest) async throws -> PolymarketRedeemRecord {
        guard !isClaimInProgress else {
            throw Error.claimInProgress
        }

        isClaimInProgress = true

        defer { isClaimInProgress = false }

        let addresses = try await depositWalletResolver.resolve()
        let calls = try await redeemService.calls(for: request)
        let nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)

        let batch = PolymarketRelayedBatch.Unsigned(
            depositWalletAddress: addresses.depositWallet,
            nonce: nonce,
            deadline: makeDeadline(),
            calls: calls
        )

        let signed = try await signer.sign(batch, as: addresses.owner)

        return try await settledRecord(for: try await submit(signed))
    }

    func makeDeadline() -> String {
        String(Int(serverClock.now.timeIntervalSince1970) + Constants.deadlineOffset)
    }

    func submit(_ batch: PolymarketRelayedBatch) async throws -> PolymarketRedeemRecord {
        do {
            return try await redeemService.submit(batch)
        } catch {
            guard case .other(.connection) = error else {
                throw error
            }

            PolymarketLogger.warning("The claim submission got no answer, resending the same batch")

            return try await redeemService.submit(batch)
        }
    }

    func settledRecord(for record: PolymarketRedeemRecord) async throws -> PolymarketRedeemRecord {
        if record.state.isTerminal {
            return try settled(record)
        }

        try? await pollDelayProvider.wait(for: Constants.pollingInterval)

        let polling = PollingSequence(
            interval: Constants.pollingInterval,
            request: { [redeemService] in try await redeemService.record(ofClaim: record.transactionId) },
            delayProvider: pollDelayProvider
        )

        var latest = record

        for await result in polling.prefix(Constants.pollingAttempts) {
            guard let polled = result.value else {
                if case .failure(PolymarketRedeemError.notFound) = result {
                    throw PolymarketRedeemError.notFound
                }

                PolymarketLogger.warning("A claim status request went unanswered, still waiting")
                continue
            }

            guard polled.state.isTerminal else {
                latest = polled
                continue
            }

            return try settled(polled)
        }

        throw Error.claimUnconfirmed(latest)
    }

    func settled(_ record: PolymarketRedeemRecord) throws -> PolymarketRedeemRecord {
        guard record.state != .failed else {
            throw Error.claimFailed(record)
        }

        return record
    }

    func presentable(_ error: Swift.Error) -> Swift.Error {
        if Task.isCancelled {
            return CancellationError()
        }

        switch error {
        case let failure as Error:
            return failure

        case let signingFailure as PolymarketSigningError:
            if case .cancelled = signingFailure {
                return CancellationError()
            }

            PolymarketLogger.error("The claim was never signed", error: signingFailure)

            return Error.notSigned

        case PolymarketRedeemError.nothingToRedeem:
            PolymarketLogger.warning("The backend has nothing left to redeem for this position")

            return Error.nothingToRedeem

        case let refusal as PolymarketRedeemError:
            PolymarketLogger.error("The backend refused the claim", error: refusal)

            return Error.refused(refusal)

        default:
            PolymarketLogger.error("The claim was never prepared", error: error)

            return Error.preparationFailed
        }
    }
}

// MARK: - Errors

extension PolymarketRedeemTransactionService {
    enum Error: LocalizedError {
        case claimInProgress
        case nothingToRedeem
        case notSigned
        case preparationFailed
        case claimFailed(PolymarketRedeemRecord)
        case claimUnconfirmed(PolymarketRedeemRecord)
        case refused(PolymarketRedeemError)

        var errorDescription: String? {
            switch self {
            case .claimInProgress, .nothingToRedeem, .notSigned, .preparationFailed:
                Localization.sendWithSwapSomethingWentWrong
            case .claimFailed:
                Localization.predictionClaimErrorFailed
            case .claimUnconfirmed:
                Localization.predictionClaimErrorUnconfirmed
            case .refused(let error):
                Self.message(for: error)
            }
        }
    }
}

// MARK: - What the backend's answers mean to a person

private extension PolymarketRedeemTransactionService.Error {
    static func message(for error: PolymarketRedeemError) -> String {
        switch error {
        case .relayerRejected:
            Localization.predictionClaimErrorRejected
        // [REDACTED_TODO_COMMENT]
        case .notFound:
            "There is no record of this claim."
        case .upstreamUnavailable:
            Localization.predictionClaimErrorUnavailable
        case .unauthorized, .badRequest, .nothingToRedeem, .cancelled, .other:
            Localization.predictionClaimErrorGeneric
        }
    }
}

// MARK: - Constants

private extension PolymarketRedeemTransactionService {
    enum Constants {
        static let deadlineOffset = 600
        static let pollingInterval: TimeInterval = 3
        static let pollingAttempts = 80
    }
}
