//
//  NewsDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// A news link names either one article or the list it belongs to.
extension NewsDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard let newsId else {
            let coordinator = NewsListCoordinator(dismissAction: { context.dismiss() })
            coordinator.start(with: .init(initialCategoryId: categoryId, presentSource: .deeplink))

            return .ready(context.sheet(context.embedInNavigationStack { NewsListCoordinatorView(coordinator: coordinator) }))
        }

        return .ready(context.sheet(context.makeNewsDetailsView(newsId: newsId)))
    }
}
