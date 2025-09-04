//
//  YieldModulePromoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

/// YIELD [REDACTED_TODO_COMMENT]
struct YieldModulePromoView: View {
    // MARK: - Properties

    let viewModel: YieldModulePromoViewModel

    // MARK: - Sub Views

    private var background: some View {
        Colors.Background.primary.ignoresSafeArea()
    }

    private var topLogo: some View {
        ZStack {
            Circle()
                .foregroundStyle(Colors.Icon.accent.opacity(0.1))
                .frame(size: .init(bothDimensions: 72))

            Assets.YieldModule.yieldPromoTopLogo.image
                .resizable()
                .renderingMode(.template)
                .frame(size: .init(bothDimensions: 34))
                .foregroundStyle(Colors.Icon.accent)
        }
    }

    private var title: some View {
        Text(Localization.yieldModulePromoScreenTitle(viewModel.annualYield))
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
    }

    private var pillInfoButton: some View {
        Button(action: { viewModel.openInterestRateInfo() }) {
            HStack(spacing: 4) {
                Text(Localization.yieldModulePromoScreenVariableRateInfo).style(Fonts.Bold.caption1, color: Colors.Text.secondary)

                Image(systemName: "info.circle")
                    .resizable()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Colors.Control.unchecked)
            .clipShape(Capsule())
        }
    }

    private var benefitsStack: some View {
        VStack(spacing: 24) {
            BenefitRow(
                icon: Assets.YieldModule.yieldPromoLightning.image,
                title: Localization.yieldModulePromoScreenCashOutTitle,
                subtitle: Localization.yieldModulePromoScreenCashOutSubtitle
            )

            BenefitRow(
                icon: Assets.YieldModule.yieldPromoSync.image,
                title: Localization.yieldModulePromoScreenAutoBalanceTitle,
                subtitle: Localization.yieldModulePromoScreenAutoBalanceSubtitle
            )

            BenefitRow(
                icon: Assets.YieldModule.yieldPromoGuard.image,
                title: Localization.yieldModulePromoScreenSelfCustodialTitle,
                subtitle: Localization.yieldModulePromoScreenSelfCustodialSubtitle
            )
        }
    }

    private var tosAndPrivacy: some View {
        VStack(spacing: 2) {
            Text(Localization.yieldModulePromoScreenTermsDisclaimer)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            HStack(spacing: 4) {
                Text(Localization.commonTermsOfUse)
                    .font(Fonts.Regular.footnote)
                    .tint(Colors.Text.accent)
                    .onTapGesture {
                        viewModel.onOpenTosTap()
                    }

                Text(Localization.commonAnd).style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Text(Localization.commonPrivacyPolicy)
                    .font(Fonts.Regular.footnote)
                    .tint(Colors.Text.accent)
                    .onTapGesture {
                        viewModel.onOpenPrivacyPolicyTap()
                    }
            }
        }
    }

    private var continueButton: some View {
        Button(action: { viewModel.onContinueButtonTapped() }) {
            Text(Localization.commonContinue)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.tangemStyle)
    }

    // MARK: - View Body

    var body: some View {
        ZStack {
            background

            VStack(spacing: .zero) {
                Spacer()

                topLogo.padding(.bottom, 20)

                title.padding(.bottom, 12)

                pillInfoButton.padding(.bottom, 32)

                benefitsStack.padding(.horizontal, 40)

                Spacer()

                tosAndPrivacy.padding(.bottom, 16)

                continueButton
                    .padding(.bottom, 6)
                    .padding(.horizontal, 16)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Localization.yieldModulePromoScreenHowItWorksButtonTitle) {
                    viewModel.onHowItWorksTap()
                }
                .foregroundColor(Colors.Text.primary1)
            }
        }
    }
}

private extension YieldModulePromoView {
    struct BenefitRow: View {
        let icon: Image
        let title: String
        let subtitle: String

        private var iconView: some View {
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(bothDimensions: 24))
                .contentShape(Rectangle())
        }

        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                iconView

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).style(Fonts.Bold.callout, color: Colors.Text.primary1)
                    Text(subtitle).style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }

                Spacer()
            }
        }
    }
}
