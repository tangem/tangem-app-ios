//
//  NewsArticleDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension NewsArticleDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        // The article checks itself against the link it arrived in.
        InjectedValues[\.newsDeeplinkValidationService].setDeeplinkURL(deeplinkString)

        return .ready(context.sheet(context.makeNewsDetailsView(newsId: newsId)))
    }
}
