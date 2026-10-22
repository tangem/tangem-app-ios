//
//  MobileSocialAgreementView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct MobileSocialAgreementView: View {
    @ObservedObject var viewModel: MobileSocialAgreementViewModel

    @ScaledMetric private var iconSide: CGFloat = 76
    @ScaledMetric private var iconOffset: CGFloat = 8
    @ScaledMetric private var iconBorderWidth: CGFloat = 4
    @ScaledMetric private var checkmarksSpacing: CGFloat = 12
    @ScaledMetric private var checkmarkSpacing: CGFloat = 12
    @ScaledMetric private var infoSpacing: CGFloat = 8

    var body: some View {
        content
            .padding(.horizontal, Layout.contentHorizontalPadding)
            .background {
                DesignSystem.Color.bgPrimary.ignoresSafeArea(edges: .top)
            }
            .onFirstAppear(perform: viewModel.onFirstAppear)
    }
}

// MARK: - Subviews

private extension MobileSocialAgreementView {
    var content: some View {
        VStack(alignment: .leading, spacing: .zero) {
            toolbar

            brandIcons
                .padding(.top, Layout.brandIconsTopPadding)

            infoView
                .padding(.top, Layout.infoTopPadding)

            Spacer()

            checkmarks

            action
                .padding(.top, Layout.actionTopPadding)
        }
    }

    var toolbar: some View {
        TopNavigationActions(actions: .one(.close(action: viewModel.onCloseTap)))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var brandIcons: some View {
        ZStack {
            makeBrandIcon(DesignSystem.Icons.LogoTangem.regular32)
                .alignmentGuide(HorizontalAlignment.center) {
                    $0[HorizontalAlignment.leading] + iconOffset
                }

            makeBrandIcon(DesignSystem.Icons.LogoApple.regular32)
                .alignmentGuide(HorizontalAlignment.center) {
                    $0[HorizontalAlignment.trailing] - iconOffset
                }
        }
    }

    var infoView: some View {
        VStack(alignment: .leading, spacing: infoSpacing) {
            Text(viewModel.infoTitle)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(viewModel.infoDescription)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .tint(DesignSystem.Color.textPrimary)
                .environment(\.openURL, OpenURLAction { url in
                    viewModel.onLearnMoreTap(url: url)
                    return .handled
                })
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, Layout.infoHorizontalPadding)
        .padding(.vertical, Layout.infoVerticalPadding)
    }

    var checkmarks: some View {
        VStack(spacing: checkmarksSpacing) {
            makeCheckmark(
                title: viewModel.emailSharingTitle,
                isOn: $viewModel.isEmailSharingAccepted,
                hasWarning: false
            )

            makeCheckmark(
                title: viewModel.lossRiskTitle,
                isOn: $viewModel.isLossRiskAccepted,
                hasWarning: viewModel.hasLossRiskWarning
            )
        }
        .padding(.vertical, Layout.checkmarksVerticalPadding)
    }

    var action: some View {
        Button(
            label: viewModel.actionTitle,
            accessibilityLabel: nil,
            action: viewModel.onActionTap
        )
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .size(.x12)
    }

    func makeCheckmark(title: String, isOn: Binding<Bool>, hasWarning: Bool) -> some View {
        let color = hasWarning ? DesignSystem.Color.textStatusError : DesignSystem.Color.textPrimary
        return HStack(spacing: checkmarkSpacing) {
            Checkbox(isOn: isOn)
                .expandsHitArea(false)
                .accessibilityLabel(title)

            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: color)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
                .onTapGesture { isOn.wrappedValue.toggle() }
        }
    }

    func makeBrandIcon(_ imageType: ImageType) -> some View {
        ZStack {
            Circle()
                .strokeBorder(DesignSystem.Color.bgPrimary, lineWidth: iconBorderWidth)
                .background(DesignSystem.Color.bgSecondary, in: .circle)

            imageType.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
        .frame(width: iconSide, height: iconSide)
    }
}

// MARK: - Layout

private extension MobileSocialAgreementView {
    enum Layout {
        static let contentHorizontalPadding: CGFloat = 16
        static let brandIconsTopPadding: CGFloat = 16
        static let infoTopPadding: CGFloat = 16
        static let infoHorizontalPadding: CGFloat = 8
        static let infoVerticalPadding: CGFloat = 12
        static let checkmarksVerticalPadding: CGFloat = 8
        static let actionTopPadding: CGFloat = 12
    }
}
