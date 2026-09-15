//
//  PolymarketDepositWalletPoller.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct PolymarketDepositWalletPoller {
    private let walletService: PolymarketDepositWalletService
    private let ownerAddress: String
    private let depositWalletAddress: String
    private let interval: TimeInterval
    private let delayProvider: PollDelayProvider

    public init(
        walletService: PolymarketDepositWalletService,
        ownerAddress: String,
        depositWalletAddress: String,
        interval: TimeInterval,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.walletService = walletService
        self.ownerAddress = ownerAddress
        self.depositWalletAddress = depositWalletAddress
        self.interval = interval
        self.delayProvider = delayProvider
    }

    public func poll(
        until target: PolymarketDepositWalletStatus,
        from initial: PolymarketDepositWalletStatus,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws -> Outcome {
        try await poll(from: initial, reporting: continuation) { $0.satisfies(target) }
    }

    public func pollUntilRecognised(
        from initial: PolymarketDepositWalletStatus,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws -> Outcome {
        PolymarketLogger.warning("The backend reports an unrecognised status, waiting for one we know")

        return try await poll(from: initial, reporting: continuation) { $0 != .unknown }
    }
}

// MARK: - Private implementation

private extension PolymarketDepositWalletPoller {
    func poll(
        from initial: PolymarketDepositWalletStatus,
        reporting continuation: PolymarketOnboardingContinuation,
        until isSatisfied: (PolymarketDepositWalletStatus) -> Bool
    ) async throws -> Outcome {
        var reported: PolymarketDepositWalletStatus?
        var consecutiveNetworkFailures = 0

        for await result in makeSequence().prefix(Constants.maxAttempts) {
            switch result {
            case .success(let wallet):
                consecutiveNetworkFailures = 0

                try wallet.ensureMatches(derived: depositWalletAddress)

                let status = wallet.status

                if status != reported {
                    reported = status
                    continuation.yield(.working(status))
                }

                if isSatisfied(status) {
                    return .reached(status)
                }

                if let failure = status.onboardingFailure {
                    throw failure
                }

            case .failure(let error):
                guard let walletError = error as? PolymarketWalletError else {
                    throw PolymarketOnboardingError.unknown
                }

                guard walletError.isTransport else {
                    throw PolymarketOnboardingError.wallet(walletError)
                }

                consecutiveNetworkFailures += 1

                guard consecutiveNetworkFailures <= Constants.toleratedNetworkFailures else {
                    throw PolymarketOnboardingError.wallet(walletError)
                }
            }
        }

        try Task.checkCancellation()

        return .ceiling(reported ?? initial)
    }

    func makeSequence() -> PollingSequence<PolymarketDepositWallet> {
        PollingSequence(
            interval: interval,
            request: { [walletService, ownerAddress] in
                try await walletService.depositWalletState(ownerAddress: ownerAddress)
            },
            delayProvider: delayProvider
        )
    }
}

// MARK: - Outcome

public extension PolymarketDepositWalletPoller {
    enum Outcome {
        case reached(PolymarketDepositWalletStatus)
        case ceiling(PolymarketDepositWalletStatus)
    }
}

// MARK: - Transport failures

private extension PolymarketWalletError {
    var isTransport: Bool {
        switch self {
        case .upstreamUnavailable:
            true
        case .other(let apiError):
            apiError.isConnection
        case .badRequest, .unauthorized, .conflict, .relayerRejected, .cancelled:
            false
        }
    }
}

private extension PolymarketAPIError {
    var isConnection: Bool {
        guard case .connection = self else { return false }

        return true
    }
}

// MARK: - Constants

public extension PolymarketDepositWalletPoller {
    enum Constants {
        public static let interval: TimeInterval = 2.5

        static let maxAttempts = 48
        static let toleratedNetworkFailures = 3
    }
}
