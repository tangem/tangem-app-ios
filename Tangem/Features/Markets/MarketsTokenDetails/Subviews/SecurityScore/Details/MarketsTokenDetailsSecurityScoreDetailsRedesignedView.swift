//
//  MarketsTokenDetailsSecurityScoreDetailsRedesignedView.swift
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

struct MarketsTokenDetailsSecurityScoreDetailsRedesignedView: View {
    let viewModel: MarketsTokenDetailsSecurityScoreDetailsViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                content
                    .padding(.horizontal, .unit(.x4))
                    .padding(.bottom, .unit(.x4))
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = Color.Tangem.Surface.level3
            config.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var header: some View {
        BottomSheetHeaderView(
            title: viewModel.title,
            titleAccessibilityIdentifier: MarketsAccessibilityIdentifiers.securityScoreDetailsTitle,
            trailing: {
                TangemButton(content: .icon(Assets.Glyphs.cross20ButtonNew)) {
                    viewModel.closeAction?()
                }
                .setStyleType(.secondary)
                .setCornerStyle(.rounded)
                .setSize(.x9)
                .setHorizontalLayout(.intrinsic)
            }
        )
        .titleStyle(Font.Tangem.Heading17.semibold, color: Color.Tangem.Text.Neutral.primary)
        .padding(.horizontal, .unit(.x4))
        .padding(.top, .unit(.x3))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: .unit(.x3)) {
            Text(viewModel.subtitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            MarketsTokenDetailsSecurityScoreProvidersSection(viewModel: viewModel)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    let helper = MarketsTokenDetailsSecurityScoreRatingHelper()

    MarketsTokenDetailsSecurityScoreDetailsRedesignedView(
        viewModel: .init(
            providers: [
                .init(
                    name: "Provider #1",
                    iconURL: URL(string: "about:blank")!,
                    ratingViewData: .init(
                        ratingBullets: helper.makeRatingBullets(forSecurityScoreValue: 2.5),
                        securityScore: helper.makeSecurityScore(forSecurityScoreValue: 2.5)
                    ),
                    auditDate: Date().formatted(date: .numeric, time: .omitted),
                    auditURL: URL(string: "https://www.certik.com")
                ),
                .init(
                    name: "Provider #2",
                    iconURL: URL(string: "about:blank")!,
                    ratingViewData: .init(
                        ratingBullets: helper.makeRatingBullets(forSecurityScoreValue: 4.5),
                        securityScore: helper.makeSecurityScore(forSecurityScoreValue: 4.5)
                    ),
                    auditDate: Date().formatted(date: .numeric, time: .omitted),
                    auditURL: URL(string: "https://www.certik.com")
                ),
            ],
            routable: nil
        )
    )
}
#endif // DEBUG
