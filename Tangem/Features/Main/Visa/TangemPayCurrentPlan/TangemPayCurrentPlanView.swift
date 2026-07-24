//
//  TangemPayCurrentPlanView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayCurrentPlanView: View {
    @ObservedObject var viewModel: TangemPayCurrentPlanViewModel

    var body: some View {
        content
            .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                changePlanButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .modifyView { view in
                if #unavailable(iOS 26.0) {
                    view.backportTranslucentNavigationBar()
                } else {
                    view
                }
            }
            .redesigned()
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let downgradeBanner = viewModel.downgradeBanner {
                    downgradeBannerView(downgradeBanner)
                }

                ForEach(viewModel.sections) { section in
                    sectionView(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    private func downgradeBannerView(_ banner: TangemPayCurrentPlanViewModel.DowngradeBanner) -> some View {
        let stayTitle = Localization.tangempayCurrentPlanStayButton(banner.planName)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                DesignSystem.Icons.Info.regular20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(DesignSystem.Color.iconStatusInfo)

                Text(banner.text)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TangemButtonV2(
                label: AttributedString(stayTitle),
                accessibilityLabel: stayTitle,
                action: viewModel.stayOnPlus
            )
            .size(.x8)
            .styleType(.secondary)
            .horizontalLayout(.infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(DesignSystem.Color.bgStatusInfoSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionView(_ section: TangemPayCurrentPlanViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    TangemRow(title: row.value, subtitle: row.label)
                        .lineOrder(.secondaryFirst)
                        .titleLineLimit(nil)
                        .showDivider(index < section.rows.count - 1)
                }
            }
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var changePlanButton: some View {
        TangemButtonV2(
            label: AttributedString(viewModel.changePlanButtonTitle),
            accessibilityLabel: viewModel.changePlanButtonTitle,
            action: viewModel.changePlan
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(alignment: .bottom) {
            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 4) {
                Text(Localization.tangempayCurrentPlanTitle)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(viewModel.planName)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
    }
}
