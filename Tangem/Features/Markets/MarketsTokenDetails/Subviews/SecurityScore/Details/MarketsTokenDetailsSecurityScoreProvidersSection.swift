//
//  MarketsTokenDetailsSecurityScoreProvidersSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsTokenDetailsSecurityScoreProvidersSection: View {
    let viewModel: MarketsTokenDetailsSecurityScoreDetailsViewModel
    var backgroundColor: Color = DesignSystem.Color.bgTertiary

    var body: some View {
        GroupedSection(viewModel.providers) { provider in
            HStack(spacing: .zero) {
                makeLeadingComponent(with: provider)

                Spacer()

                makeTrailingComponent(with: provider)
            }
            .padding(.vertical, Constants.defaultVerticalPadding)
        }
        .backgroundColor(backgroundColor)
    }

    private func makeLeadingComponent(
        with provider: MarketsTokenDetailsSecurityScoreDetailsViewModel.SecurityScoreProviderData
    ) -> some View {
        HStack(spacing: 12.0) {
            IconView(url: provider.iconURL, size: .init(bothDimensions: 36.0), forceKingfisher: true)

            VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
                Text(provider.name)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                if let auditDate = provider.auditDate {
                    Text(auditDate)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
        }
    }

    private func makeTrailingComponent(
        with provider: MarketsTokenDetailsSecurityScoreDetailsViewModel.SecurityScoreProviderData
    ) -> some View {
        SwiftUI.Button(
            action: {
                viewModel.onProviderLinkTap(with: provider.id)
            },
            label: {
                VStack(alignment: .trailing, spacing: Constants.defaultVerticalSpacing) {
                    MarketsTokenDetailsSecurityScoreRatingView(viewData: provider.ratingViewData)

                    if let auditURLTitle = provider.auditURLTitle {
                        HStack(spacing: 4.0) {
                            Text(auditURLTitle)

                            Assets.arrowRightUpMini.image
                                .resizable()
                                .renderingMode(.template)
                                .frame(size: .init(bothDimensions: 16.0))
                        }
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    }
                }
            }
        )
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreDetailsProviderLink)
        .disabled(provider.auditURLTitle == nil)
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsSecurityScoreProvidersSection {
    enum Constants {
        static let defaultVerticalPadding = 14.0
        static let defaultVerticalSpacing = 2.0
    }
}
