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

struct MarketsTokenDetailsSecurityScoreProvidersSection: View {
    let viewModel: MarketsTokenDetailsSecurityScoreDetailsViewModel
    var backgroundColor: Color = Colors.Background.action

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
                    .style(Fonts.Bold.subheadline.weight(.medium), color: Colors.Text.primary1)

                if let auditDate = provider.auditDate {
                    Text(auditDate)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
        }
    }

    private func makeTrailingComponent(
        with provider: MarketsTokenDetailsSecurityScoreDetailsViewModel.SecurityScoreProviderData
    ) -> some View {
        Button(
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
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
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
