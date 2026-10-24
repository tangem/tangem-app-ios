//
//  WelcomeLegalViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Everything the welcome screen needs to put a legal document on screen. The two pages are authored
/// differently, so the surface each one sits on travels with the model rather than being picked apart
/// again by the view.
struct WelcomeLegalViewModel: Identifiable {
    let id = UUID()
    let webViewModel: WebViewContainerViewModel
    let backgroundStyle: AnyShapeStyle
    let colorScheme: ColorScheme

    init(document: WelcomeLegalDocument) {
        webViewModel = WebViewContainerViewModel(
            url: document.url,
            title: "",
            withCloseButton: true,
            withNavigationBar: false
        )

        switch document {
        case .termsOfService:
            // The page ships both palettes and switches on `prefers-color-scheme`, so it renders itself
            // correctly under the scheme welcome runs in and only needs the backing the onboarding TOS has.
            backgroundStyle = AnyShapeStyle(.ultraThinMaterial)
            colorScheme = .dark
        case .privacyPolicy:
            // Black text on a background the page never declares. The web view is non-opaque, so without
            // a light page under it the document would inherit the black welcome screen.
            backgroundStyle = AnyShapeStyle(.white)
            colorScheme = .light
        }
    }
}
