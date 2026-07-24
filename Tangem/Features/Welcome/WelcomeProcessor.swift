//
//  WelcomeProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Owns the Welcome flow's async inputs, publishing a `State` for the coordinator to render straight from its
/// two facts: whether the startup onboarding is up, and which deep link — if any — is pending.
final class WelcomeProcessor {
    var statePublisher: AnyPublisher<State, Never> {
        $state.removeDuplicates().eraseToAnyPublisher()
    }

    @Published private(set) var state: State = .initial

    private var bag: Set<AnyCancellable> = []

    init(isIdle: AnyPublisher<Bool, Never>) {
        bind(isIdle: isIdle)
    }

    deinit {
        AppLogger.debug("WelcomeProcessor deinit")
    }

    func welcomeOnboardingDismissed() {
        state.welcomeOnboarding = nil
    }

    /// Computes the initial state, then subscribes to the deep-link flags. Reading them for the initial state
    /// and subscribing in the same call means a flag that flips in between can't slip through. `isIdle` holds
    /// each reaction until the user is back on the Welcome screen, so we don't present over a screen they
    /// navigated to themselves.
    private func bind(isIdle: AnyPublisher<Bool, Never>) {
        state = State(startupOnboarding: WelcomeOnboardingsHelper().getStartupOnboarding())

        if FeatureProvider.isAvailable(.hideStoriesInMobileWallet) {
            AppSettings.shared.$shouldShowMobilePromoWalletSelector
                .filter { $0 }
                .combineLatest(isIdle)
                .filter { _, isIdle in isIdle }
                .first()
                .receiveOnMain()
                .withWeakCaptureOf(self)
                .sink { processor, _ in
                    processor.setDeepLink(.promo)
                }
                .store(in: &bag)
        }

        AppSettings.shared.$needsTangemPayMobileOnboarding
            .filter { $0 }
            .combineLatest(isIdle)
            .filter { _, isIdle in isIdle }
            .first()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { processor, _ in
                processor.setDeepLink(.tangemPay)
            }
            .store(in: &bag)
    }

    /// The first deep link wins — they're mutually exclusive, so a later one shouldn't override the shown one.
    private func setDeepLink(_ deepLink: State.DeepLink) {
        guard state.deepLink == nil else { return }

        state.deepLink = deepLink
    }
}

// MARK: - State

extension WelcomeProcessor {
    struct State: Equatable {
        /// Steps of the startup welcome onboarding (TOS/push). While present it gates the deep link behind it.
        var welcomeOnboarding: [WelcomeOnboardingStep]?
        /// The single pending deep link: Tangem Pay shows modally over the stories, promo/referral navigates on
        /// to create wallet. Mutually exclusive — hence one optional.
        var deepLink: DeepLink?

        enum DeepLink: Equatable {
            case tangemPay
            case promo
        }
    }
}

// MARK: - Initial state

extension WelcomeProcessor.State {
    /// Neutral value held until `bind` computes the real state during `init`; never rendered.
    static let initial = Self(welcomeOnboarding: nil, deepLink: nil)

    init(startupOnboarding: WelcomeStartupOnboarding?) {
        switch startupOnboarding {
        case .welcome(let steps):
            welcomeOnboarding = steps
            deepLink = nil
        case .tangemPayMobile:
            welcomeOnboarding = nil
            deepLink = .tangemPay
        case .none:
            welcomeOnboarding = nil
            deepLink = nil
        }
    }
}
