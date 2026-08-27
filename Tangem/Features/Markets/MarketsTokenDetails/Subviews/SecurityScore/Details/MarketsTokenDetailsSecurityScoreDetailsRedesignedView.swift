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
import TangemLocalization
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .readGeometry(\.size.height) { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(DesignSystem.Color.bgPrimary)
        // iOS 26 sheets use a concentric corner radius matching the device; only override below it.
        .if(!isLiquidGlassSupported) { $0.presentationCornerRadius(24) }
    }

    private var header: some View {
        BottomSheetHeaderView(
            title: viewModel.title,
            titleAccessibilityIdentifier: MarketsAccessibilityIdentifiers.securityScoreDetailsTitle,
            trailing: {
                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: { viewModel.closeAction?() }
                )
                .size(.x9)
                .styleType(.secondary)
            }
        )
        .titleFont(DesignSystem.Font.bodyMediumToken.font) // [REDACTED_INFO]: tracking deferred
        .titleColor(DesignSystem.Color.textPrimary)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            MarketsTokenDetailsSecurityScoreProvidersSection(
                viewModel: viewModel,
                backgroundColor: DesignSystem.Color.bgSecondary
            )
        }
    }
}

// MARK: - Previews

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
