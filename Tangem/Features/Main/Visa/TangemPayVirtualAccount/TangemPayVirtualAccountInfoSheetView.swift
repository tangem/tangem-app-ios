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
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)

            TangemButtonV2(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Localization.commonClose, action: viewModel.close)
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

            feeSection
                .padding(.top, 24)

            banner
        }
        .padding(.top, 8)
    }

    private var icon: some View {
        Assets.Visa.fiatToUsdc.image
            .frame(width: 160, height: 80)
    }

    private var texts: some View {
        VStack(spacing: 8) {
            Text(Localization.tangempayBankTransferIntroTitle)
                .font(token: DesignSystem.Font.headingMediumToken)
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
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text(Localization.tangempayBankTransferFeeHeader)
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)

                Spacer(minLength: 0)
            }

            feeRow(title: "ACH", value: "$1")

            DesignSystem.Color.borderSecondary
                .frame(height: 2)

            feeRow(title: "FedWire", value: "$11")
        }
    }

    private func feeRow(title: String, value: String) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: title)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            Spacer(minLength: 0)

            Text(verbatim: value)
                .font(token: DesignSystem.Font.bodyMediumToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
        }
    }

    private var banner: some View {
        HStack(alignment: .center, spacing: 8) {
            DesignSystem.Icons.Info.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconStatusInfo)

            Text(Localization.tangempayBankTransferSwiftWarning)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(DesignSystem.Color.bgStatusInfoSubtle, in: RoundedRectangle(cornerRadius: 14))
    }

    private var footer: some View {
        VStack(spacing: 16) {
            TangemButtonV2(
                label: AttributedString(Localization.tangempayBankTransferShowDetails),
                accessibilityLabel: Localization.tangempayBankTransferShowDetails,
                action: viewModel.showDetails
            )
            .styleType(.default)
            .size(.x14)
            .horizontalLayout(.infinity)
            .isLoading(viewModel.isLoading)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountShowDetailsButton)

            Text(viewModel.agreementText)
                .environment(\.openURL, OpenURLAction { url in
                    viewModel.openURL(url)
                    return .handled
                })
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SizeUnit.x3.value)
        }
        .padding(.top, 24)
    }
}
