//
//  TangemPayReceiveSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
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
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
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
        VStack(spacing: .zero) {
            warningBanner
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            addressBlock
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 40)

            actionButtons
                .padding(16)
        }
    }

    var warningBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            DesignSystem.Icons.Info.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconStatusInfo)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.warningTitle)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                Text(Localization.receiveBottomSheetWarningMessageDescription)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(DesignSystem.Color.bgStatusInfoSubtle, in: RoundedRectangle(cornerRadius: 16))
    }

    var addressBlock: some View {
        VStack(spacing: 32) {
            HStack(spacing: 12) {
                ForEach(viewModel.tokenIcons) { tokenIcon in
                    icon(for: tokenIcon)
                }
            }

            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(viewModel.heading)
                        .multilineTextAlignment(.center)
                        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                    SUILabel(attributedAddress)
                        .animation(nil, value: viewModel.address)
                }

                copyButton
            }
        }
    }

    func icon(for tokenIcon: TangemPayReceiveSheetViewModel.TokenIconViewData) -> some View {
        iconContent(for: tokenIcon)
            .overlay(Circle().strokeBorder(DesignSystem.Color.borderSecondary, lineWidth: 1))
            .networkIconOverlay(
                imageAsset: tokenIcon.networkIcon,
                iconSize: CGSize(bothDimensions: 26),
                borderWidth: 2,
                borderColor: DesignSystem.Color.bgSecondary,
                isShimmerEnabled: false
            )
    }

    @ViewBuilder
    func iconContent(for tokenIcon: TangemPayReceiveSheetViewModel.TokenIconViewData) -> some View {
        if tokenIcon.url == nil {
            Text(tokenIcon.symbol)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(4)
                .frame(size: CGSize(bothDimensions: Constants.tokenIconSize))
                .background(DesignSystem.Color.bgOpaquePrimary, in: Circle())
        } else {
            IconView(
                url: tokenIcon.url,
                size: CGSize(bothDimensions: Constants.tokenIconSize),
                cornerRadius: Constants.tokenIconSize / 2,
                forceKingfisher: true
            )
        }
    }

    var attributedAddress: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.alignment = .center

        let token = DesignSystem.Font.subheadingMediumToken

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

    var copyButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.commonCopy),
            accessibilityLabel: Localization.commonCopy,
            action: viewModel.copy
        )
        .iconEnd(DesignSystem.Icons.Copy.regular20)
        .size(.x8)
        .styleType(.outline)
        .horizontalLayout(.intrinsic)
    }

    var actionButtons: some View {
        HStack(spacing: 8) {
            TangemUI.Button(
                label: AttributedString(Localization.tokenReceiveShowQrCodeTitle),
                accessibilityLabel: Localization.tokenReceiveShowQrCodeTitle,
                action: viewModel.showQRCode
            )
            .iconEnd(DesignSystem.Icons.Qr.regular24)
            .size(.x12)
            .styleType(.secondary)
            .horizontalLayout(.infinity)

            TangemUI.Button(
                label: AttributedString(Localization.commonShare),
                accessibilityLabel: Localization.commonShare,
                action: viewModel.share
            )
            .iconEnd(DesignSystem.Icons.ShareIos.regular24)
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
        }
    }

    enum Constants {
        static let tokenIconSize: CGFloat = 80
    }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
