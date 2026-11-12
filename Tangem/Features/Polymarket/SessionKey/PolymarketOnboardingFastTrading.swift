//
//  PolymarketOnboardingFastTrading.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketOnboardingFastTrading: AnyObject {
    var isEnabled: Bool { get set }

    func makeAuthorization(depositWalletAddress: String, approvalsNonce: String, followsApprovals: Bool) -> PolymarketRelayedBatch.Unsigned?

    @discardableResult
    func submit(_ authorization: PolymarketRelayedBatch) -> Task<Void, Never>?

    func reportNotEnabled()
}

final class CommonPolymarketOnboardingFastTrading {
    typealias Authorize = (_ batch: PolymarketRelayedBatch, _ grant: PolymarketSessionKeyGrant) async throws -> Void
    typealias Report = (_ failure: PolymarketFastTradingFailure) async -> Void

    private let authorizations: PolymarketSessionKeyAuthorizations
    private let authorize: Authorize
    private let report: Report
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(
        authorizations: PolymarketSessionKeyAuthorizations,
        authorize: @escaping Authorize,
        report: @escaping Report
    ) {
        self.authorizations = authorizations
        self.authorize = authorize
        self.report = report
    }
}

// MARK: - PolymarketOnboardingFastTrading protocol conformance

extension CommonPolymarketOnboardingFastTrading: PolymarketOnboardingFastTrading {
    var isEnabled: Bool {
        get { state.withLock { $0.isEnabled } }
        set { state.withLock { $0.isEnabled = newValue } }
    }

    func makeAuthorization(depositWalletAddress: String, approvalsNonce: String, followsApprovals: Bool) -> PolymarketRelayedBatch.Unsigned? {
        do {
            let nonce = try followsApprovals ? PolymarketSessionKeyAuthorizationBatch.nonce(following: approvalsNonce) : approvalsNonce
            let authorization = try authorizations.makeFollowUp(depositWalletAddress: depositWalletAddress, nonce: nonce)

            state.withLock { $0.pendingGrant = authorization.grant }

            return authorization.unsigned
        } catch {
            PolymarketLogger.error("Failed to prepare the fast trading authorization for onboarding", error: error)
            reportNotEnabled()
            return nil
        }
    }

    @discardableResult
    func submit(_ authorization: PolymarketRelayedBatch) -> Task<Void, Never>? {
        let grant = state.withLock { state in
            defer { state.pendingGrant = nil }
            return state.pendingGrant
        }

        guard let grant else { return nil }

        let authorize = authorize
        let report = report

        return Task {
            do {
                try await authorize(authorization, grant)
            } catch {
                PolymarketLogger.error(
                    error: "The fast trading authorization signed during onboarding did not go through: \(PolymarketFastTradingFailure.logDescription(of: error))"
                )

                guard PolymarketFastTradingFailure(error: error) != nil else { return }

                await report(.onboardingActivationFailed)
            }
        }
    }

    func reportNotEnabled() {
        let report = report

        Task {
            await report(.onboardingActivationFailed)
        }
    }
}

// MARK: - Auxiliary types

private extension CommonPolymarketOnboardingFastTrading {
    struct State {
        var isEnabled = true
        var pendingGrant: PolymarketSessionKeyGrant?
    }
}
