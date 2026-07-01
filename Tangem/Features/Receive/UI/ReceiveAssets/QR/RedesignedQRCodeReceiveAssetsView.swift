//
//  RedesignedQRCodeReceiveAssetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct RedesignedQRCodeReceiveAssetsView: View {
    @ObservedObject var viewModel: QRCodeReceiveAssetsViewModel

    var body: some View {
        VStack(spacing: 8) {
            qrCard

            actionsButtons
        }
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .id(viewModel.addressInfo.address)
    }

    private var qrCard: some View {
        VStack(spacing: 32) {
            headerText

            VStack(spacing: 16) {
                qrImage

                addressBlock

                memoWarning
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private var headerText: some View {
        Text(viewModel.headerForAddress(with: viewModel.addressInfo))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }

    private var qrImage: some View {
        Image(uiImage: viewModel.addressInfo.addressQRImage)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 249)
            .layoutPriority(0)
            .disableAnimations()
            .accessibilityIdentifier(QRCodeAccessibilityIdentifiers.qrCodeImage)
    }

    private var addressBlock: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(Localization.commonAddress)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .accessibilityIdentifier(QRCodeAccessibilityIdentifiers.addressHeader)

            Button {
                viewModel.copyToClipboard()
            } label: {
                SUILabel(viewModel.stringForAddress(viewModel.addressInfo.address))
                    .contentShape(Rectangle())
                    .animation(nil, value: viewModel.addressInfo)
            }
            .accessibilityIdentifier(QRCodeAccessibilityIdentifiers.addressText)
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private var memoWarning: some View {
        if let memoWarningMessage = viewModel.memoWarningMessage {
            Text(memoWarningMessage)
                .multilineTextAlignment(.center)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                .animation(nil, value: viewModel.addressInfo)
        }
    }

    private var actionsButtons: some View {
        HStack(spacing: 8) {
            TangemButtonV2(
                label: AttributedString(Localization.commonCopy),
                iconStart: DesignSystem.Icons.Copy.regular24,
                accessibilityLabel: Localization.commonCopy,
                action: viewModel.copyToClipboard
            )
            .size(.x12)
            .styleType(.secondary)
            .horizontalLayout(.infinity)

            TangemButtonV2(
                label: AttributedString(Localization.commonShare),
                iconStart: DesignSystem.Icons.ShareIos.regular24,
                accessibilityLabel: Localization.commonShare,
                action: viewModel.share
            )
            .size(.x12)
            .styleType(.secondary)
            .horizontalLayout(.infinity)
        }
    }
}
