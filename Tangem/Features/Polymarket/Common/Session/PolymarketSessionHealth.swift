//
//  PolymarketSessionHealth.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketSessionHealthChecking: AnyObject {
    @discardableResult
    func verify() async -> PolymarketSessionVerdict

    @discardableResult
    func report(_ status: PolymarketDepositWalletStatus) async -> PolymarketSessionVerdict
}

enum PolymarketSessionVerdict: Equatable {
    case ready
    case reconnectRequired
    case inconclusive
}

final class PolymarketSessionHealth {
    private let walletService: PolymarketDepositWalletService
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let resetOnboarding: (_ isAccountGone: Bool) -> Void

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let reconnectHandler = OSAllocatedUnfairLock<(() -> Void)?>(uncheckedState: nil)
    private var listeningTask: Task<Void, Never>?

    init(
        walletService: PolymarketDepositWalletService,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        unauthorizedEvents: AsyncStream<Void>,
        resetOnboarding: @escaping (_ isAccountGone: Bool) -> Void
    ) {
        self.walletService = walletService
        self.ownerAddressProvider = ownerAddressProvider
        self.resetOnboarding = resetOnboarding

        listeningTask = Task { [weak self] in
            for await _ in unauthorizedEvents {
                await self?.verify()
            }
        }
    }

    deinit {
        listeningTask?.cancel()
    }

    func setReconnectHandler(_ handler: @escaping () -> Void) {
        reconnectHandler.withLockUnchecked { $0 = handler }
    }
}

// MARK: - Verdicts

extension PolymarketSessionVerdict {
    init(status: PolymarketDepositWalletStatus) {
        switch status {
        case .readyToTrade:
            self = .ready
        case .unknown:
            self = .inconclusive
        case .notCreated, .deploymentInProgress, .deployed, .approvalsInProgress, .deploymentFailed, .approvalsFailed:
            self = .reconnectRequired
        }
    }

    init(error: PolymarketWalletError) {
        switch error {
        case .unauthorized:
            self = .reconnectRequired
        case .other(.http(let statusCode, _)) where statusCode == Constants.notFoundStatusCode:
            self = .reconnectRequired
        case .cancelled:
            self = .inconclusive
        case .badRequest, .conflict, .relayerRejected, .upstreamUnavailable, .other:
            PolymarketLogger.error("The wallet status could not be confirmed", error: error)
            self = .inconclusive
        }
    }
}

private extension PolymarketSessionVerdict {
    enum Constants {
        static let notFoundStatusCode = 404
    }
}

// MARK: - PolymarketSessionHealthChecking protocol conformance

extension PolymarketSessionHealth: PolymarketSessionHealthChecking {
    @discardableResult
    func verify() async -> PolymarketSessionVerdict {
        await join { [weak self] in
            await self?.readOutcome() ?? Outcome(verdict: .inconclusive, status: nil)
        }
    }

    @discardableResult
    func report(_ status: PolymarketDepositWalletStatus) async -> PolymarketSessionVerdict {
        let reported = Outcome(verdict: PolymarketSessionVerdict(status: status), status: status)
        let verdict = await join { reported }

        guard verdict == .inconclusive, reported.verdict == .reconnectRequired else {
            return verdict
        }

        conclude(reported)

        return reported.verdict
    }
}

// MARK: - Private implementation

private extension PolymarketSessionHealth {
    func join(_ evaluation: @escaping () async -> Outcome) async -> PolymarketSessionVerdict {
        let check = state.withLockUnchecked { state -> Check in
            if state.isReconnectRequired {
                return .concluded
            }

            if let running = state.running {
                return .running(running)
            }

            let running = Task { [weak self] in
                let outcome = await evaluation()
                self?.finish(outcome)
                return outcome.verdict
            }

            state.running = running

            return .running(running)
        }

        switch check {
        case .concluded:
            return .reconnectRequired
        case .running(let task):
            return await task.value
        }
    }

    func finish(_ outcome: Outcome) {
        state.withLock { $0.running = nil }

        conclude(outcome)
    }

    func conclude(_ outcome: Outcome) {
        let isFirstReconnect = state.withLock { state -> Bool in
            guard outcome.verdict == .reconnectRequired, !state.isReconnectRequired else {
                return false
            }

            state.isReconnectRequired = true

            return true
        }

        guard isFirstReconnect else { return }

        PolymarketLogger.warning("The wallet is no longer ready to trade, the account has to be connected again")

        resetOnboarding(outcome.status == .notCreated)
        reconnectHandler.withLockUnchecked { $0 }?()
    }

    func readOutcome() async -> Outcome {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            return Outcome(verdict: .inconclusive, status: nil)
        }

        do {
            let depositWallet = try await walletService.depositWalletState(ownerAddress: ownerAddress)

            return Outcome(verdict: PolymarketSessionVerdict(status: depositWallet.status), status: depositWallet.status)
        } catch {
            return Outcome(verdict: PolymarketSessionVerdict(error: error), status: nil)
        }
    }
}

// MARK: - Auxiliary types

private extension PolymarketSessionHealth {
    struct State {
        var running: Task<PolymarketSessionVerdict, Never>?
        var isReconnectRequired = false
    }

    struct Outcome {
        let verdict: PolymarketSessionVerdict
        let status: PolymarketDepositWalletStatus?
    }

    enum Check {
        case concluded
        case running(Task<PolymarketSessionVerdict, Never>)
    }
}
