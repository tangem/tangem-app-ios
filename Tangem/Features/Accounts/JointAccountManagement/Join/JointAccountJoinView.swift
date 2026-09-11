//
//  JointAccountJoinView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct JointAccountJoinView: View {
    @ObservedObject var viewModel: JointAccountJoinViewModel

    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            glow

            VStack(spacing: .zero) {
                accountIcon
                    .infinityFrame()

                content
            }
        }
        .topNavigation(leading: .none, onClose: viewModel.onCloseTap)
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var glow: some View {
        RoundedRectangle(cornerRadius: Constants.glowCornerRadius, style: .continuous)
            .fill(viewModel.accountIconViewData.backgroundColor)
            .frame(height: Constants.glowHeight)
            .padding(.horizontal, Constants.glowHorizontalPadding)
            .blur(radius: Constants.glowBlurRadius)
            .opacity(Constants.glowOpacity)
            .offset(y: -Constants.glowHeight / 2)
    }

    private var accountIcon: some View {
        AccountIconView(data: viewModel.accountIconViewData, settings: .extraLargeSized)
            .overlay(accountIconHighlight)
            .clipShape(accountIconShape)
            .overlay {
                accountIconShape
                    .strokeBorder(
                        DesignSystem.Color.borderPrimary,
                        lineWidth: Constants.accountIconBorderWidth
                    )
            }
    }

    private var accountIconHighlight: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(Constants.accountIconHighlightOpacity),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var accountIconShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: Constants.accountIconSize * Constants.accountIconCornerRadiusRatio,
            style: .continuous
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: .zero) {
            JointAccountHeaderTitle(title: viewModel.title, subtitle: viewModel.subtitle)
                .padding(.horizontal, Constants.titleHorizontalPadding)
                .padding(.vertical, Constants.titleVerticalPadding)

            rows
                .padding(.horizontal, Constants.rowsHorizontalPadding)
        }
    }

    private var rows: some View {
        VStack(spacing: .zero) {
            creatorRow

            if viewModel.isWalletSelectionAvailable {
                walletRow
            }
        }
    }

    private var creatorRow: some View {
        Row(title: Localization.jointAccountInviteMembersCreator, value: viewModel.creatorName)
            .overrideTextColors(.init(value: DesignSystem.Color.textSecondary))
            .valueAccessory {
                icon(DesignSystem.Icons.Info.regular20, color: DesignSystem.Color.iconSecondary)
            }
            .showDivider(viewModel.isWalletSelectionAvailable)
            .onTap(viewModel.onCreatorInfoTap)
    }

    private var walletRow: some View {
        Row(title: Localization.commonWallet)
            .valueAccessory { walletValue }
            .onTap(viewModel.onWalletTap)
    }

    private var walletValue: some View {
        HStack(spacing: Constants.walletValueSpacing) {
            walletImage

            Text(viewModel.walletName)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            icon(DesignSystem.Icons.ChevronDown.regular16, color: DesignSystem.Color.iconSecondary)
        }
    }

    @ViewBuilder
    private var walletImage: some View {
        if let walletImage = viewModel.walletImage {
            walletImage.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: Constants.walletImageSize)
        }
    }

    private var footer: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil
        ) {
            viewModel.onContinueTap()
        }
        .styleType(.default)
        .horizontalLayout(.infinity)
        .size(.x12)
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.bottom, Constants.footerBottomPadding)
    }

    private func icon(_ imageType: ImageType, color: Color) -> some View {
        imageType.image
            .renderingMode(.template)
            .foregroundStyle(color)
    }
}

// MARK: - Constants

private extension JointAccountJoinView {
    enum Constants {
        static let glowCornerRadius: CGFloat = 138
        static let glowHeight: CGFloat = 422
        static let glowHorizontalPadding: CGFloat = 13
        static let glowBlurRadius: CGFloat = 80
        static let glowOpacity: CGFloat = 0.2

        static let accountIconSize: CGFloat = 128
        static let accountIconCornerRadiusRatio: CGFloat = 0.28
        static let accountIconBorderWidth: CGFloat = 2
        static let accountIconHighlightOpacity: CGFloat = 0.2

        static let titleHorizontalPadding: CGFloat = 24
        static let titleVerticalPadding: CGFloat = 12
        static let rowsHorizontalPadding: CGFloat = 8

        static let walletValueSpacing: CGFloat = 4
        static let walletImageSize = CGSize(bothDimensions: 20)

        static let footerHorizontalPadding: CGFloat = 16
        static let footerBottomPadding: CGFloat = 12
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        JointAccountJoinView(
            viewModel: JointAccountJoinViewModel(
                preview: JointAccountInvitePreview(
                    config: JointAccountSignedConfig(
                        name: "Family savings",
                        icon: AccountModel.CompositeIcon.Name.safe.rawValue,
                        iconColor: CompositeIconColor.candyGrapeFizz.rawValue,
                        membersCount: 5,
                        threshold: 2
                    ),
                    creator: JointAccountInvitePreview.Creator(
                        name: "Isaac",
                        address: "0xBef7B36845000000000000ac4e6752A9cE000000"
                    )
                ),
                userWalletModels: FakeUserWalletModel.allFakeWalletModels,
                coordinator: nil
            )!
        )
    }
}
