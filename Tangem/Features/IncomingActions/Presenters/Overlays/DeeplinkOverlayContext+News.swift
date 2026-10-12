//
//  DeeplinkOverlayContext+News.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension DeeplinkOverlayContext {
    func makeNewsDetailsView(newsId: Int) -> AnyView {
        embedInNavigationStack {
            NewsDeeplinkContainerView(newsId: newsId, dismissAction: { dismiss() })
        }
    }
}
