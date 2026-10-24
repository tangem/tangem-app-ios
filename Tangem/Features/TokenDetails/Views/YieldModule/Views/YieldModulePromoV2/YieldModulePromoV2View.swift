//
//  YieldModulePromoV2View.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemAccessibilityIdentifiers

struct YieldModulePromoV2View: View {
    // MARK: - Properties

    let viewModel: YieldModulePromoV2ViewModel

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View Body

    var body: some View {
        ZStack {
            background

            VStack(spacing: .zero) {
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .top) {
                        headerImage

                        contentStack
                            .padding(.top, Constants.contentTopOffset)
                            .padding(.horizontal, 24)
                    }
                }
                .ignoresSafeArea(edges: .top)

                bottomStack
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 6)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SwiftUI.Button(Localization.yieldModulePromoScreenHowItWorksButtonTitle) {
                    viewModel.onHowItWorksTap()
                }
                .foregroundColor(Colors.Text.primary1)
            }
        }
    }

    // MARK: - Sub Views

    private var background: some View {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()
    }

    /// The asset catalog drops the artwork's SVG glow filter, so the shadows redraw it off the bars' alpha. They are
    /// stacked rather than chained: a chained `.shadow` blurs the previous halo instead of the artwork itself. The
    /// artwork keeps its own size — scaling it to the screen width would drag the bars away from the content below.
    private var headerImage: some View {
        Color.clear
            .frame(height: Constants.artworkHeight)
            .overlay {
                ZStack {
                    artwork.shadow(color: Constants.glowGreen.opacity(0.2), radius: 9, y: 7)
                    artwork.shadow(color: Constants.glowGreen.opacity(0.7), radius: 63, y: 7)

                    // The white lift exists to separate the glow from the dark background the design is drawn on.
                    if colorScheme == .dark {
                        artwork.shadow(color: .white.opacity(0.8), radius: 99, y: 7)
                    }

                    artwork
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private var artwork: some View {
        Assets.YieldModule.yieldModulePromoV2Header.image
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: .zero) {
            ratePillsRow.padding(.bottom, 12)
            title.padding(.bottom, 24)
            pointsStack
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: some View {
        Text(viewModel.title)
            .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
            .multilineTextAlignment(.leading)
    }

    private var ratePillsRow: some View {
        HStack(spacing: 4) {
            variableRatePill

            if let chipText = viewModel.incentivisedChipText {
                incentivisedRatePill(text: chipText)
            }
        }
    }

    private var variableRatePill: some View {
        SwiftUI.Button(action: { viewModel.onVariableRateInfoTap() }) {
            pillLabel(
                text: Localization.yieldModulePromoScreenVariableRateInfoV2,
                textColor: DesignSystem.Color.textSecondary,
                iconColor: DesignSystem.Color.iconSecondary,
                backgroundColor: DesignSystem.Color.bgTransparentPrimary
            )
        }
        .padding(.vertical, -Constants.pillTouchPadding)
    }

    private func incentivisedRatePill(text: String) -> some View {
        SwiftUI.Button(action: { viewModel.onIncentiveRateInfoTap() }) {
            pillLabel(
                text: text,
                textColor: DesignSystem.Color.textStatusInfo,
                iconColor: DesignSystem.Color.iconStatusInfo,
                backgroundColor: DesignSystem.Color.bgStatusInfoSubtle
            )
        }
        .padding(.vertical, -Constants.pillTouchPadding)
    }

    private func pillLabel(text: String, textColor: Color, iconColor: Color, backgroundColor: Color) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: textColor)

            DesignSystem.Icons.Info.regular16.image
                .renderingMode(.template)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .clipShape(Capsule())
        // The capsule stays compact; the transparent padding raises the hit target to the 44pt minimum,
        // and the buttons negate it outside so the layout is unaffected.
        .padding(.vertical, Constants.pillTouchPadding)
        .contentShape(Rectangle())
    }

    private var pointsStack: some View {
        VStack(alignment: .leading, spacing: 16) {
            PointRow(
                icon: DesignSystem.Icons.Lightning.regular20.image,
                title: Localization.yieldModulePromoScreenCashOutTitle,
                subtitle: Localization.yieldModulePromoScreenCashOutSubtitle
            )

            PointRow(
                icon: DesignSystem.Icons.ArrowRefresh.regular20.image,
                title: Localization.yieldModulePromoScreenAutoBalanceTitle,
                subtitle: Localization.yieldModulePromoScreenAutoBalanceSubtitleV2(viewModel.tokenName)
            )

            PointRow(
                icon: DesignSystem.Icons.ShieldCheckmark.regular20.image,
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
        MainButton(
            title: viewModel.continueButtonTitle,
            isDisabled: viewModel.isContinueButtonDisabled,
            action: { viewModel.onContinueTap() }
        )
        .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.promoContinueButton)
    }

    private var bottomStack: some View {
        VStack(spacing: 16) {
            tosAndPrivacy
            continueButton
        }
    }
}

private extension YieldModulePromoV2View {
    enum Constants {
        /// Design offset of the content block from the screen top, measured against the artwork's own height.
        static let contentTopOffset: CGFloat = 350
        static let artworkHeight: CGFloat = 486
        static let glowGreen = Color(red: 0.047, green: 0.6235, blue: 0.2392)
        /// Grows the ~24pt pill to the 44pt accessibility touch target.
        static let pillTouchPadding: CGFloat = 10
    }

    struct PointRow: View {
        let icon: Image
        let title: String
        let subtitle: String

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(size: .init(bothDimensions: 20))
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
                    .accessibilityHidden(true)

                Group {
                    Text("\(title). ")
                        .font(Fonts.Bold.subheadline)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                        + Text(subtitle)
                        .font(Fonts.Regular.subheadline)
                        .foregroundColor(DesignSystem.Color.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: .zero)
            }
        }
    }
}
