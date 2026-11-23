//
//  PolymarketSessionKeySigningAvailability.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket

@MainActor
protocol PolymarketSessionKeySigningAvailability: AnyObject {
    var isAvailable: Bool { get }

    var availableUntil: Date? { get }

    var isAvailablePublisher: AnyPublisher<Bool, Never> { get }

    func refresh() async

    func checkReadiness() async -> PolymarketOrderSigningRoute
}

final class CommonPolymarketSessionKeySigningAvailability {
    private let service: PolymarketFastTradingStateProviding
    private let signingRouter: PolymarketOrderSigningRouting
    private let now: () -> Date

    init(
        service: PolymarketFastTradingStateProviding,
        signingRouter: PolymarketOrderSigningRouting,
        now: @escaping () -> Date = { InjectedValues[\.polymarketServerClock].now }
    ) {
        self.service = service
        self.signingRouter = signingRouter
        self.now = now
    }
}

// MARK: - PolymarketSessionKeySigningAvailability protocol conformance

extension CommonPolymarketSessionKeySigningAvailability: PolymarketSessionKeySigningAvailability {
    var isAvailable: Bool {
        Self.isAvailable(in: service.state, at: now(), isRefused: signingRouter.isRefused(sessionKeyAddress:))
    }

    var availableUntil: Date? {
        Self.availableUntil(in: service.state, at: now(), isRefused: signingRouter.isRefused(sessionKeyAddress:))
    }

    var isAvailablePublisher: AnyPublisher<Bool, Never> {
        let now = now
        let signingRouter = signingRouter

        return service.statePublisher
            .map { Self.isAvailable(in: $0, at: now(), isRefused: signingRouter.isRefused(sessionKeyAddress:)) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func refresh() async {
        await service.refresh()
    }

    func checkReadiness() async -> PolymarketOrderSigningRoute {
        await signingRouter.route()
    }
}

// MARK: - Decision

extension CommonPolymarketSessionKeySigningAvailability {
    static func isAvailable(
        in state: PolymarketFastTradingState,
        at date: Date,
        isRefused: (String) -> Bool
    ) -> Bool {
        guard case .loaded(let assessment) = state else {
            return false
        }

        return assessment.signingKey(at: date, isRefused: isRefused) != nil
    }

    static func availableUntil(
        in state: PolymarketFastTradingState,
        at date: Date,
        isRefused: (String) -> Bool
    ) -> Date? {
        guard case .loaded(let assessment) = state, let sessionKey = assessment.signingKey(at: date, isRefused: isRefused) else {
            return nil
        }

        return assessment.usableUntil(sessionKey)
    }
}

// MARK: - Signing key

private extension PolymarketFastTradingAssessment {
    var isIdle: Bool {
        !isOperationInFlight
    }

    func signingKey(at date: Date, isRefused: (String) -> Bool) -> PolymarketSessionKey? {
        guard isIdle, case .active(let sessionKey) = status, isUsable(sessionKey, at: date, isRefused: isRefused) else {
            return nil
        }

        return sessionKey
    }

    func isUsable(_ sessionKey: PolymarketSessionKey, at date: Date, isRefused: (String) -> Bool) -> Bool {
        sessionKey.isUsable(at: date) && isUsableOnExchange(sessionKey, at: date) && !isRefused(sessionKey.address)
    }
}
