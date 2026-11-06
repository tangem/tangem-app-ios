//
//  PromoPageDeeplink+Overlay.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension PromoPageDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard FeatureProvider.isAvailable(.promoPage), let page, let url = PromoPageURLValidator().validatedURL(from: page) else {
            return nil
        }

        let overlayId = context.id
        let viewModel = PromoPageViewModel(url: url, dismiss: {
            guard InjectedValues[\.overlayViewPresentingStateProvider].presentedOverlayId == overlayId else {
                return
            }

            InjectedValues[\.overlayViewPresenter].dismiss()
        })

        return .ready(context.sheet(context.embedInNavigationStack { PromoPageView(viewModel: viewModel) }))
    }
}
