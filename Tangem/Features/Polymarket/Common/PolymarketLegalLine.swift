//
//  PolymarketLegalLine.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct PolymarketLegalLine: View {
    private let onTermsTap: (URL) -> Void

    init(onTermsTap: @escaping (URL) -> Void) {
        self.onTermsTap = onTermsTap
    }

    var body: some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .tint(DesignSystem.Color.textPrimary)
            .environment(\.openURL, OpenURLAction { url in
                onTermsTap(url)
                return .handled
            })
    }

    private var text: AttributedString {
        let polymarketTerms = Localization.predictionOnboardingLegalPolymarketTerms
        let tangemTerms = Localization.predictionOnboardingLegalTangemTerms

        var text = AttributedString(Localization.predictionOnboardingLegal(polymarketTerms, tangemTerms))

        link(polymarketTerms, to: Constants.polymarketTermsURL, in: &text)
        link(tangemTerms, to: AppConstants.tosURL, in: &text)

        return text
    }

    private func link(_ title: String, to url: URL, in text: inout AttributedString) {
        guard let range = text.range(of: title) else {
            return
        }

        text[range].foregroundColor = DesignSystem.Color.textPrimary
        text[range].link = url
    }
}

// MARK: - Constants

private extension PolymarketLegalLine {
    enum Constants {
        static let polymarketTermsURL = URL(string: "https://polymarket.com/tos")!
    }
}
