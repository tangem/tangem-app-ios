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
}

final class CommonPolymarketSessionKeySigningAvailability {
    private let service: PolymarketFastTradingServicing
    private let signingRouter: PolymarketOrderSigningRouting
    private let now: () -> Date

    init(
        service: PolymarketFastTradingServicing,
        signingRouter: PolymarketOrderSigningRouting,
        now: @escaping () -> Date = Date.init
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
}

// MARK: - Decision

extension CommonPolymarketSessionKeySigningAvailability {
    static func isAvailable(
        in state: PolymarketFastTradingState,
        at date: Date,
        isRefused: (String) -> Bool
    ) -> Bool {
        guard
            case .loaded(let assessment) = state,
            !assessment.isOperationInFlight,
            case .active(let sessionKey) = assessment.status,
            assessment.isUsableOnExchange(sessionKey, at: date),
            !isRefused(sessionKey.address)
        else {
            return false
        }

        return sessionKey.isUsable(at: date)
    }

    static func availableUntil(
        in state: PolymarketFastTradingState,
        at date: Date,
        isRefused: (String) -> Bool
    ) -> Date? {
        guard
            isAvailable(in: state, at: date, isRefused: isRefused),
            case .loaded(let assessment) = state,
            case .active(let sessionKey) = assessment.status
        else {
            return nil
        }

        return assessment.usableUntil(sessionKey)
    }
}
