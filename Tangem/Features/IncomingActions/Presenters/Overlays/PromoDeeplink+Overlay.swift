//
//  PromoDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension PromoDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        let view = AnyView(
            PromocodeActivationView(promoCode: code, dismissAction: { context.dismiss() })
                .presentationBackground(.clear)
        )

        // The view does its own fade, so the cover it rides in has nothing to animate.
        return .ready(context.cover(view, animated: false))
    }
}
