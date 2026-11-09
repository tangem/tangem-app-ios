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

@MainActor
final class PolymarketOrderSigningChoice: ObservableObject {
    @Published private(set) var signsWithSessionKey: Bool

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
        now: @escaping () -> Date = Date.init,
        showNotice: @escaping @MainActor (String) -> Void = PolymarketFastTradingToast.showInfo
    ) {
        self.availability = availability
        self.delayProvider = delayProvider
        self.now = now
        self.showNotice = showNotice

        signsWithSessionKey = availability.isAvailable

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

    func signing(tappedWithSessionKey: Bool) -> PolymarketOrderSigningMethod? {
        guard tappedWithSessionKey else {
            return .ownerKey
        }

        guard availability.isAvailable, !isSessionKeyDeclined else {
            switchToOwnerKey()
            return nil
        }

        return .sessionKey
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

// MARK: - Private implementation

private extension PolymarketOrderSigningChoice {
    func apply(isAvailable: Bool) {
        signsWithSessionKey = isAvailable && !isSessionKeyDeclined
        scheduleExpiry()
    }

    func switchToOwnerKey() {
        signsWithSessionKey = false
        expiryTask?.cancel()
        showNotice(PolymarketFastTradingStrings.sessionKeyUnavailableNotice)
    }

    func scheduleExpiry() {
        expiryTask?.cancel()

        guard signsWithSessionKey, let availableUntil = availability.availableUntil else {
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
