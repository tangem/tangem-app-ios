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

struct YieldModulePromoView: View {
    // MARK: - Properties

    let viewModel: YieldModulePromoViewModel

    // MARK: - View Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack {
                background

                VStack(spacing: 98) {
                    VStack(spacing: .zero) {
                        topLogo.padding(.bottom, 20)

                        title.padding(.bottom, 12)

                        pillInfoButton.padding(.bottom, 34)

                        benefitsStack
                    }
                    .padding(.top, 70)
                    .padding(.horizontal, 40)

                    VStack(spacing: 16) {
                        tosAndPrivacy
                        continueButton
                    }
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

    // MARK: - Sub Views

    private var background: some View {
        Colors.Background.primary.ignoresSafeArea()
    }

    private var topLogo: some View {
        Assets.YieldModule.yieldModuleLogo.image
            .resizable()
            .frame(size: .init(bothDimensions: 72))
    }

    private var title: some View {
        Text(Localization.yieldModulePromoScreenTitle(viewModel.apy))
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
        VStack(spacing: 26) {
            BenefitRow(
                icon: Assets.YieldModule.yieldModuleLightning.image,
                title: Localization.yieldModulePromoScreenCashOutTitle,
                subtitle: Localization.yieldModulePromoScreenCashOutSubtitle
            )

            BenefitRow(
                icon: Assets.YieldModule.yieldModuleSync.image,
                title: Localization.yieldModulePromoScreenAutoBalanceTitle,
                subtitle: Localization.yieldModulePromoScreenAutoBalanceSubtitle
            )

            BenefitRow(
                icon: Assets.YieldModule.yieldModuleShield.image,
                title: Localization.yieldModulePromoScreenSelfCustodialTitle,
                subtitle: Localization.yieldModulePromoScreenSelfCustodialSubtitle
            )
        }
    }

    private var tosAndPrivacy: some View {
        Text(viewModel.makeTosAndPrivacyString()).multilineTextAlignment(.center)
    }

    private var continueButton: some View {
        Button(action: {}) {
            Text(Localization.commonContinue)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.tangemStyle)
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).style(Fonts.Bold.callout, color: Colors.Text.primary1)
                    Text(subtitle).style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }

                Spacer()
            }
        }
    }
}
