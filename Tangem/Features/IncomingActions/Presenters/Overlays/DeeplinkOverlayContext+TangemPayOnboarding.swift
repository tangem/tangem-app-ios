//
//  DeeplinkOverlayContext+TangemPayOnboarding.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension DeeplinkOverlayContext {
    /// The offer both Tangem Pay onboarding links open; each says where it came from, because onboarding
    /// validates a link before showing it. `nil` — the offer isn't available to any wallet on this device.
    func makeTangemPayOnboardingOverlay(source: TangemPayOnboardingSource) -> DeeplinkOverlayResult? {
        let availability = InjectedValues[\.tangemPayAvailabilityRepository].tangemPayOfferAvailability

        guard let availableSelection = availability.availableWalletSelection else {
            return nil
        }

        let coordinator = coordinatorFactory.makeTangemPayOnboardingCoordinator { _ in dismiss() }
        coordinator.start(with: .init(source: source, availableSelection: availableSelection))

        return .ready(cover(AnyView(TangemPayOnboardingCoordinatorView(coordinator: coordinator))))
    }
}
