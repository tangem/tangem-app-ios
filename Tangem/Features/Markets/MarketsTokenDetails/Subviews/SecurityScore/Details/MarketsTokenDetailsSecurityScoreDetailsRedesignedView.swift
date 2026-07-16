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

    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    private var detentHeight: CGFloat {
        (headerHeight + contentHeight).rounded(.up)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .readGeometry(\.size.height) { headerHeight = $0 }

            ScrollView {
                content
                    .padding(.horizontal, .unit(.x4))
                    .padding(.bottom, .unit(.x4))
                    .readGeometry(\.size.height) { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.Tangem.Surface.level2)
        // iOS 26 sheets use a concentric corner radius matching the device; only override below it.
        .if(!isLiquidGlassSupported) { $0.presentationCornerRadius(24) }
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

            MarketsTokenDetailsSecurityScoreProvidersSection(
                viewModel: viewModel,
                backgroundColor: Color.Tangem.Surface.level3
            )
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
