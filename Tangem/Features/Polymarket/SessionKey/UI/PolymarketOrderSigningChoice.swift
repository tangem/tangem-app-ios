//
//  PolymarketOrderSigningChoice.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPolymarket

@MainActor
final class PolymarketOrderSigningChoice: ObservableObject {
    @Published private(set) var method: PolymarketOrderSigningMethod

    private let availability: PolymarketSessionKeySigningAvailability
    private let delayProvider: PollDelayProvider
    private let now: () -> Date
    private let showNotice: @MainActor (String) -> Void
    private var readinessCheck: Task<PolymarketOrderSigningRoute, Never>?
    private var isSessionKeyDeclined = false
    private var isNotReady = false
    private var expiryTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        availability: PolymarketSessionKeySigningAvailability,
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider(),
        now: @escaping () -> Date = { InjectedValues[\.polymarketServerClock].now },
        showNotice: @escaping @MainActor (String) -> Void = PolymarketFastTradingToast.showInfo
    ) {
        self.availability = availability
        self.delayProvider = delayProvider
        self.now = now
        self.showNotice = showNotice

        method = availability.isAvailable ? .sessionKey : .ownerKey

        availability.isAvailablePublisher
            .sink { [weak self] isAvailable in
                self?.update(isAvailable: isAvailable)
            }
            .store(in: &bag)

        Task { await availability.refresh() }
    }

    deinit {
        readinessCheck?.cancel()
        expiryTask?.cancel()
    }

    func decide(tapped: PolymarketOrderSigningMethod) async -> Decision {
        switch tapped {
        case .ownerKey:
            return .sign(.ownerKey)
        case .sessionKey:
            guard
                let route = await latestReadiness(),
                allowsSessionKey(isAvailable: availability.isAvailable),
                case .sessionKey = route
            else {
                return .routeChanged
            }

            return .sign(route)
        }
    }

    func switchToOwnerKey() {
        method = .ownerKey
        expiryTask?.cancel()
        showNotice(PolymarketFastTradingStrings.sessionKeyUnavailableNotice)
    }

    func declineSessionKey() {
        isSessionKeyDeclined = true
        switchToOwnerKey()

        Task { [availability] in await availability.refresh() }
    }
}

// MARK: - Decision

extension PolymarketOrderSigningChoice {
    enum Decision: Equatable {
        case sign(PolymarketOrderSigningRoute)
        case routeChanged
    }
}

// MARK: - Private implementation

private extension PolymarketOrderSigningChoice {
    func allowsSessionKey(isAvailable: Bool) -> Bool {
        isAvailable && !isSessionKeyDeclined && !isNotReady
    }

    func update(isAvailable: Bool) {
        if isAvailable {
            checkReadiness()
        }

        apply(isAvailable: isAvailable)
    }

    func checkReadiness() {
        let check = Task { [availability] in await availability.checkReadiness() }
        readinessCheck = check

        Task { [weak self] in
            let route = await check.value

            guard let self, check == readinessCheck else { return }

            apply(readiness: route)
        }
    }

    func latestReadiness() async -> PolymarketOrderSigningRoute? {
        while let check = readinessCheck {
            let route = await check.value

            if check == readinessCheck {
                apply(readiness: route)
                return route
            }
        }

        return nil
    }

    func apply(readiness route: PolymarketOrderSigningRoute) {
        let isNotReady = route == .ownerKey

        guard isNotReady != self.isNotReady else { return }

        self.isNotReady = isNotReady
        apply(isAvailable: availability.isAvailable)
    }

    func apply(isAvailable: Bool) {
        method = allowsSessionKey(isAvailable: isAvailable) ? .sessionKey : .ownerKey
        scheduleExpiry()
    }

    func scheduleExpiry() {
        expiryTask?.cancel()

        guard method == .sessionKey, let availableUntil = availability.availableUntil else {
            return
        }

        let delay = max(0, availableUntil.timeIntervalSince(now()))

        expiryTask = Task { [weak self, delayProvider] in
            try? await delayProvider.wait(for: delay)

            guard !Task.isCancelled, let self else { return }

            apply(isAvailable: availability.isAvailable)
        }
    }
}
