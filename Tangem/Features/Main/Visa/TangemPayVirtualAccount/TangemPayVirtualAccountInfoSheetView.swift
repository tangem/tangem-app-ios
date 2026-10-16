//
//  TangemPayVirtualAccountInfoSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TangemPayVirtualAccountInfoSheetView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountInfoSheetViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                content
            }

            footer
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .animation(.contentFrameUpdate, value: viewModel.state)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            TangemUI.Button(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Localization.commonClose, action: viewModel.close)
                .size(.x11)
                .styleType(.material(.glass))
        }
        .padding(.top, 16)
    }

    private var content: some View {
        VStack(spacing: 24) {
            icon
                .padding(.top, 32)

            texts

            VStack(spacing: viewModel.state == .failed ? 10 : 12) {
                feeSection

                banner
            }
            .padding(.top, 24)
        }
        .padding(.top, 8)
    }

    private var icon: some View {
        HStack(spacing: -16) {
            Circle()
                .fill(DesignSystem.Color.bgTransparentPrimary)
                .frame(width: 80, height: 80)
                .overlay {
                    Circle().strokeBorder(DesignSystem.Color.borderSecondary, lineWidth: 1)
                }
                .overlay {
                    Assets.Visa.fiat.image
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(DesignSystem.Color.textPrimary)
                }

            Assets.Visa.usdc.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay {
                    Circle().strokeBorder(DesignSystem.Color.borderSecondary, lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    Assets.Visa.pol.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .padding(2)
                        .background(DesignSystem.Color.bgSecondary, in: Circle())
                        .offset(x: 2, y: -2)
                }
        }
    }

    private var texts: some View {
        VStack(spacing: 8) {
            Text(Localization.tangempayBankTransferIntroTitle)
                .font(token: DesignSystem.Font.headingSmallToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            Text(Localization.tangempayBankTransferIntroSubtitle)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
    }

    private var feeSection: some View {
        TangemPayVirtualAccountFeeListView(
            header: Localization.tangempayBankTransferFeeHeader,
            state: viewModel.state,
            rowsHorizontalPadding: 16,
            reload: viewModel.reloadFees
        )
    }

    private var banner: some View {
        HStack(alignment: .top, spacing: 8) {
            DesignSystem.Icons.Info.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconStatusInfo)

            Text(Localization.tangempayBankTransferSwiftWarning)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(DesignSystem.Color.bgStatusInfoSubtle, in: RoundedRectangle(cornerRadius: 16))
    }

    private var footer: some View {
        VStack(spacing: 16) {
            TangemUI.Button(
                label: AttributedString(Localization.tangempayBankTransferShowDetails),
                accessibilityLabel: Localization.tangempayBankTransferShowDetails,
                action: viewModel.showDetails
            )
            .styleType(.primary)
            .size(.x12)
            .horizontalLayout(.infinity)
            .loading(.spinner(if: viewModel.isLoading))
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountShowDetailsButton)

            if let agreementText = viewModel.agreementText {
                Text(agreementText)
                    .environment(\.openURL, OpenURLAction { url in
                        viewModel.openURL(url)
                        return .handled
                    })
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)
                    .tint(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
        .padding(.top, 28)
    }
}

// MARK: - Animations

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
