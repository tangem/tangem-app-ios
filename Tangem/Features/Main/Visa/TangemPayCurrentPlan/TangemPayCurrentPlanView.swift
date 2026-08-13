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
            .alert(item: $viewModel.alert) { $0.alert }
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
                if let banner = viewModel.awaitingDepositBanner {
                    TangemPayCurrentPlanInfoBanner(
                        title: banner.text,
                        button: TangemPayCurrentPlanInfoBannerButton(
                            title: banner.cancelButtonTitle,
                            isLoading: viewModel.isCancellingTransition,
                            action: viewModel.cancelTransition
                        )
                    )
                }

                if let banner = viewModel.downgradeBanner {
                    TangemPayCurrentPlanInfoBanner(
                        title: banner.text,
                        button: TangemPayCurrentPlanInfoBannerButton(
                            title: Localization.tangempayCurrentPlanStayButton(banner.planName),
                            action: viewModel.stayOnPlus
                        )
                    )
                }

                if let feeChargedBannerText = viewModel.feeChargedBannerText {
                    TangemPayCurrentPlanInfoBanner(title: feeChargedBannerText)
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

    private func sectionView(_ section: TangemPayCurrentPlanViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    Row(title: row.value, subtitle: row.label)
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

    @ViewBuilder
    private var changePlanButton: some View {
        if viewModel.isPlanChangeAvailable {
            TangemUI.Button(
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
