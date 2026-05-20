//
//  OnboardingTermsOfServiceFooter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct OnboardingTermsOfServiceFooter: View {
    let onTap: () -> Void

    private var attributedText: AttributedString {
        let link = Localization.disclaimerTitle
        let full = Localization.onboardingCreateWalletTermOfConditionsText(link)
        var attributed = AttributedString(full)
        attributed.font = Fonts.Regular.footnote
        attributed.foregroundColor = Colors.Text.tertiary
        if let range = attributed.range(of: link) {
            attributed[range].link = AppConstants.tosURL
            attributed[range].foregroundColor = Colors.Text.accent
        }
        return attributed
    }

    var body: some View {
        Text(attributedText)
            .multilineTextAlignment(.center)
            // `.link` on AttributedString is set only to make the link range tappable;
            // the actual destination lives in AppConstants.tosURL, so the URL passed
            // here is ignored and we forward the tap to the parent via `onTap`.
            .environment(\.openURL, OpenURLAction { _ in
                onTap()
                return .handled
            })
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    OnboardingTermsOfServiceFooter(onTap: {})
        .padding()
}
#endif // DEBUG
