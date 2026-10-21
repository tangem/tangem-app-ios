//
//  TangemPayReceiveSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayReceiveSheetView: View {
    @ObservedObject var viewModel: TangemPayReceiveSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header

            content
        }
        .id(viewModel.address)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(DesignSystem.Color.bgSecondary)
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }
}

// MARK: - Header

private extension TangemPayReceiveSheetView {
    var header: some View {
        BottomSheetHeaderView(
            title: Localization.domainReceiveAssetsNavigationTitle,
            leading: { backButton },
            trailing: { closeButton }
        )
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    var backButton: some View {
        if viewModel.isBackButtonVisible {
            TangemUI.Button(
                icon: DesignSystem.Icons.ChevronLeft.regular20,
                accessibilityLabel: Localization.commonBack,
                action: viewModel.onBackTap
            )
            .size(.x11)
            .styleType(.material(.glass))
        }
    }

    var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: viewModel.close
        )
        .size(.x11)
        .styleType(.material(.glass))
    }
}

// MARK: - Content

private extension TangemPayReceiveSheetView {
    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .info:
            infoContent
        case .qrCode(let qrCodeViewModel):
            RedesignedQRCodeReceiveAssetsView(viewModel: qrCodeViewModel)
        }
    }

    var infoContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                addressBlock

                RedesignedReceiveNotificationsView(inputs: viewModel.notificationInputs)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    var addressBlock: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.tokenIcons) { tokenIcon in
                            icon(for: tokenIcon)
                        }
                    }

                    VStack(spacing: 4) {
                        Text(viewModel.heading)
                            .multilineTextAlignment(.center)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.multichainReceiveSheetHeading)

                        SUILabel(attributedAddress)
                            .animation(nil, value: viewModel.address)
                            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.multichainReceiveSheetAddress)
                    }
                    .padding(.horizontal, 24)
                }

                showQRCodeButton
            }

            actionButtons
        }
        .padding(16)
    }

    func icon(for tokenIcon: TangemPayReceiveSheetViewModel.TokenIconViewData) -> some View {
        TokenIcon(tokenIconInfo: tokenIcon.tokenIconInfo, size: Constants.tokenIconSize, isWithOverlays: false)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.multichainReceiveSheetTokenIcon(symbol: tokenIcon.symbol))
            .networkIconOverlay(
                imageAsset: tokenIcon.networkIcon,
                iconSize: Constants.networkIconSize,
                borderWidth: Constants.networkIconBorderWidth,
                borderColor: DesignSystem.Color.bgSecondary,
                isShimmerEnabled: false
            )
    }

    var attributedAddress: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.alignment = .center

        let token = DesignSystem.Font.captionMediumToken

        return NSAttributedString(
            string: viewModel.address,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: token.fontSize, weight: .medium),
                .kern: token.tracking,
                .foregroundColor: UIColor(DesignSystem.Color.textSecondary),
            ]
        )
    }

    var showQRCodeButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.tokenReceiveShowQrCodeTitle),
            accessibilityLabel: Localization.tokenReceiveShowQrCodeTitle,
            action: viewModel.showQRCode
        )
        .iconStart(Assets.Receive.qrButtonIcon)
        .size(.x10)
        .styleType(.ghost)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.multichainReceiveSheetShowQRButton)
    }

    var actionButtons: some View {
        HStack(spacing: 8) {
            TangemUI.Button(
                label: AttributedString(Localization.commonCopy),
                accessibilityLabel: Localization.commonCopy,
                action: viewModel.copy
            )
            .iconStart(DesignSystem.Icons.Copy.regular24)
            .size(.x12)
            .styleType(.secondary(.default))
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.multichainReceiveSheetCopyButton)

            TangemUI.Button(
                label: AttributedString(Localization.commonShare),
                accessibilityLabel: Localization.commonShare,
                action: viewModel.share
            )
            .iconStart(DesignSystem.Icons.ShareIos.regular24)
            .size(.x12)
            .styleType(.secondary(.default))
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.multichainReceiveSheetShareButton)
        }
    }

    enum Constants {
        static let tokenIconSize = CGSize(bothDimensions: 56)
        static let networkIconSize = CGSize(bothDimensions: 20)
        static let networkIconBorderWidth: Double = 1
    }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
