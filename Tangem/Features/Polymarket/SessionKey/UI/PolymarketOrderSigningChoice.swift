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
    private var isSessionKeyDeclined = false
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
                self?.apply(isAvailable: isAvailable)
            }
            .store(in: &bag)

        Task { await availability.refresh() }
    }

    deinit {
        expiryTask?.cancel()
    }

    func decide(tapped: PolymarketOrderSigningMethod) -> Decision {
        switch tapped {
        case .ownerKey:
            .sign(.ownerKey)
        case .sessionKey:
            allowsSessionKey(isAvailable: availability.isAvailable) ? .sign(.sessionKey) : .routeChanged
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

    func reportUnverified() {
        showNotice(PolymarketFastTradingStrings.sessionKeyUnverifiedNotice)
    }
}

// MARK: - Decision

extension PolymarketOrderSigningChoice {
    enum Decision: Equatable {
        case sign(PolymarketOrderSigningMethod)
        case routeChanged
    }
}

// MARK: - Private implementation

private extension PolymarketOrderSigningChoice {
    func allowsSessionKey(isAvailable: Bool) -> Bool {
        isAvailable && !isSessionKeyDeclined
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
