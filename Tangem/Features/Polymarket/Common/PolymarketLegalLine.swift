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
import TangemPolymarketUI
import TangemUI

struct PolymarketLegalLine: View {
    private let notice: PolymarketLegalNotice
    private let onTermsTap: (URL) -> Void

    init(notice: PolymarketLegalNotice = .termsAgreement, onTermsTap: @escaping (URL) -> Void) {
        self.notice = notice
        self.onTermsTap = onTermsTap
    }

    var body: some View {
        Text(Self.text(notice: notice))
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .tint(DesignSystem.Color.textPrimary)
            .environment(\.openURL, Self.openURLAction(onTermsTap))
    }

    static func openURLAction(_ onTermsTap: @escaping (URL) -> Void) -> OpenURLAction {
        OpenURLAction { url in
            onTermsTap(url)
            return .handled
        }
    }

    static func text(notice: PolymarketLegalNotice = .termsAgreement) -> AttributedString {
        let polymarketTerms = Localization.predictionOnboardingLegalPolymarketTerms
        let tangemTerms = Localization.predictionOnboardingLegalTangemTerms

        var text = AttributedString(sentence(notice: notice, polymarketTerms: polymarketTerms, tangemTerms: tangemTerms))

        link(polymarketTerms, to: Constants.polymarketTermsURL, in: &text)
        link(tangemTerms, to: AppConstants.tosURL, in: &text)

        return text
    }

    private static func sentence(notice: PolymarketLegalNotice, polymarketTerms: String, tangemTerms: String) -> String {
        switch notice {
        case .termsAgreement: Localization.predictionOnboardingLegal(polymarketTerms, tangemTerms)
        case .termsAlreadyAccepted: Localization.predictionOnboardingReconnectLegal(polymarketTerms, tangemTerms)
        }
    }

    private static func link(_ title: String, to url: URL, in text: inout AttributedString) {
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
