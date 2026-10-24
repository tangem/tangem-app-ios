//
//  WelcomeEntryReasonProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol WelcomeEntryReasonProviding {
    /// Called once at app startup: the wallet-delete event that flips `Last Wallet Forgotten`
    /// fires before the Welcome screen exists, so a subscriber constructed lazily there would miss it.
    func startObserving()

    /// One-shot per welcome entry: `nil` means the event already fired this session and no new
    /// reason appeared since — returning to welcome from a sheet, stories, a legal document or an
    /// aborted terminal flow must not re-fire `Introduction Process Screen Opened`.
    func consumeEntryReason() -> Analytics.ParameterValue?
}

private struct WelcomeEntryReasonProviderKey: InjectionKey {
    static var currentValue: WelcomeEntryReasonProviding = CommonWelcomeEntryReasonProvider()
}

extension InjectedValues {
    var welcomeEntryReasonProvider: WelcomeEntryReasonProviding {
        get { Self[WelcomeEntryReasonProviderKey.self] }
        set { Self[WelcomeEntryReasonProviderKey.self] = newValue }
    }
}

final class CommonWelcomeEntryReasonProvider: WelcomeEntryReasonProviding {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private struct State {
        var didJustForgetLastWallet = false
        var didFireThisSession = false
        var didStartObserving = false
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private var bag: Set<AnyCancellable> = []

    func startObserving() {
        let shouldObserve = state.withLock { state in
            guard !state.didStartObserving else { return false }
            state.didStartObserving = true
            return true
        }

        guard shouldObserve else { return }

        // The flag is set synchronously on the emitting thread: the repository sends the delete
        // event before navigation rebuilds Welcome, so consumeEntryReason can never win the race.
        userWalletRepository.eventProvider
            .sink { [weak self] event in
                if case .deleted(_, isRepositoryEmpty: true) = event {
                    self?.state.withLock { $0.didJustForgetLastWallet = true }
                }
            }
            .store(in: &bag)
    }

    func consumeEntryReason() -> Analytics.ParameterValue? {
        let isFirstLaunch = AppSettings.shared.numberOfLaunches <= 1

        return state.withLock { state in
            defer {
                state.didJustForgetLastWallet = false
                state.didFireThisSession = true
            }

            if state.didJustForgetLastWallet {
                return .welcomeEntryLastWalletForgotten
            }

            guard !state.didFireThisSession else { return nil }

            return isFirstLaunch ? .welcomeEntryFirstLaunch : .welcomeEntryNoWallets
        }
    }
}
