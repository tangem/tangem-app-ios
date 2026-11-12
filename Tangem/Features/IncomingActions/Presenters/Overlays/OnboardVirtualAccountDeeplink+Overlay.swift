//
//  OnboardVirtualAccountDeeplink+Overlay.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension OnboardVirtualAccountDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        context.makeTangemPayOnboardingOverlay(source: onboardingSource)
    }
}
