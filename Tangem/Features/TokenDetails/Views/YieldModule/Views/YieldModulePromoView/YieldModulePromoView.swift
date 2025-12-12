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
import TangemUI

struct YieldModulePromoView: View {
    // MARK: - Properties

    let viewModel: YieldModulePromoViewModel

    // MARK: - View Body

    var body: some View {
        ZStack {
            background

            VStack(spacing: .zero) {
                GeometryReader { proxy in
                    GroupedScrollView {
                        topStack
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
                    }
                }

                bottomStack
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 6)
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
        Text(Localization.yieldModulePromoScreenTitleV2(viewModel.apyString))
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
            .multilineTextAlignment(.center)
    }

    private var pillInfoButton: some View {
        Button(action: { viewModel.onInterestRateInfoTap() }) {
            HStack(spacing: 4) {
                Text(Localization.yieldModulePromoScreenVariableRateInfoV2)
                    .style(Fonts.Bold.caption1, color: Colors.Text.secondary)

                Assets.infoCircle16.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Colors.Control.unchecked)
            .clipShape(Capsule())
        }
    }

    private var topStack: some View {
        VStack(spacing: .zero) {
            topLogo.padding(.bottom, 20)
            title.padding(.bottom, 8)
            pillInfoButton.padding(.bottom, 30)
            benefitsStack.padding(.top, 6)
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
                subtitle: Localization.yieldModulePromoScreenAutoBalanceSubtitleV2(viewModel.tokenName)
            )

            BenefitRow(
                icon: Assets.YieldModule.yieldModuleShield.image,
                title: Localization.yieldModulePromoScreenSelfCustodialTitle,
                subtitle: Localization.yieldModulePromoScreenSelfCustodialSubtitle
            )
        }
    }

    private var tosAndPrivacy: some View {
        Text(viewModel.makeTosAndPrivacyString())
            .multilineTextAlignment(.center)
            .environment(\.openURL, OpenURLAction { url in
                viewModel.openUrl(url)
                return .handled
            })
    }

    private var continueButton: some View {
        MainButton(title: Localization.commonContinue, action: { viewModel.onContinueTap() })
    }

    private var bottomStack: some View {
        VStack(spacing: 16) {
            tosAndPrivacy
            continueButton
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).style(Fonts.Bold.callout, color: Colors.Text.primary1)
                    Text(subtitle).style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                }

                Spacer()
            }
        }
    }
}
