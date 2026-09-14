//
//  CollectiblesWelcomeView+Footer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

private typealias Footer = CollectiblesWelcomeView.Footer

extension CollectiblesWelcomeView {
    struct Footer: View {
        let isLoading: Bool
        let onCreateAccountTap: () -> Void
        let onTermsTap: (URL) -> Void

        var body: some View {
            VStack(spacing: 12) {
                legalTerms

                createAccountButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Fade(position: .bottom)
                    .variant(.hard)
                    .blurred()
                    .padding(.top, -Metrics.fadeOverhang)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Footer + Content

private extension Footer {
    var legalTerms: some View {
        Text(Self.legalTermsText)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .multilineTextAlignment(.center)
            .tint(DesignSystem.Color.textPrimary)
            .environment(\.openURL, OpenURLAction { url in
                onTermsTap(url)
                return .handled
            })
    }

    var createAccountButton: some View {
        // [REDACTED_TODO_COMMENT]
        TangemUI.Button(label: "Create Packs account", accessibilityLabel: nil, action: onCreateAccountTap)
            .iconEnd(DesignSystem.Icons.LogoTangem.regular24)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
            .loading(.spinner(if: isLoading))
    }

    // [REDACTED_TODO_COMMENT]
    static let legalTermsText: AttributedString = {
        let collectorCryptTerms = "Collector Crypt T&Cs"
        let tangemTerms = "Tangem T&Cs"
        let privacyNotice = "Privacy Notice"

        var text = AttributedString(
            "By continuing, you confirm that you have read and agree to the \(collectorCryptTerms), \(tangemTerms) and \(privacyNotice)"
        )

        highlight(collectorCryptTerms, in: &text)
        highlight(tangemTerms, linkingTo: AppConstants.tosURL, in: &text)
        highlight(privacyNotice, linkingTo: AppConstants.privacyPolicyURL, in: &text)

        return text
    }()

    static func highlight(_ title: String, linkingTo url: URL? = nil, in text: inout AttributedString) {
        guard let range = text.range(of: title) else {
            return
        }

        text[range].foregroundColor = DesignSystem.Color.textPrimary
        text[range].link = url
    }
}

// MARK: - Metrics

private extension Footer {
    enum Metrics {
        static let fadeOverhang: CGFloat = 16
    }
}

// MARK: - Previews

#Preview {
    ZStack(alignment: .bottom) {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        Footer(isLoading: false, onCreateAccountTap: {}, onTermsTap: { _ in })
    }
}
