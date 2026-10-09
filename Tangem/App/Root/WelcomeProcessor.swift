//
//  WelcomeProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Owns the Welcome flow's async inputs, publishing a `State` for the coordinator to render straight from the
/// deep link — if any — that is pending.
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

    /// Computes the initial state, then subscribes to the deep-link flags. Reading them for the initial state
    /// and subscribing in the same call means a flag that flips in between can't slip through. `isIdle` holds
    /// each reaction until the user is back on the Welcome screen, so we don't present over a screen they
    /// navigated to themselves.
    private func bind(isIdle: AnyPublisher<Bool, Never>) {
        state = State(startupOnboarding: WelcomeOnboardingsHelper().getStartupOnboarding())

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

        TangemPayCampaignService().pendingCampaignKeyPublisher
            .compactMap { $0 }
            .combineLatest(isIdle)
            .filter { _, isIdle in isIdle }
            .first()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { processor, input in
                processor.setDeepLink(.tangemPayCampaign(campaignKey: input.0))
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
        /// The single pending deep link: Tangem Pay shows modally over the stories, promo/referral navigates on
        /// to create wallet. Mutually exclusive — hence one optional.
        var deepLink: DeepLink?

        enum DeepLink: Equatable {
            case tangemPay
            case tangemPayCampaign(campaignKey: String)
            case promo
        }
    }
}

// MARK: - Initial state

extension WelcomeProcessor.State {
    /// Neutral value held until `bind` computes the real state during `init`; never rendered.
    static let initial = Self(deepLink: nil)

    init(startupOnboarding: WelcomeStartupOnboarding?) {
        switch startupOnboarding {
        case .tangemPayMobile:
            deepLink = .tangemPay
        case .tangemPayCampaign(let campaignKey):
            deepLink = .tangemPayCampaign(campaignKey: campaignKey)
        case .none:
            deepLink = nil
        }
    }
}
