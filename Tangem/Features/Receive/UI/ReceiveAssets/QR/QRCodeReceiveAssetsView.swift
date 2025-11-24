//
//  QRCodeReceiveAssetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemAccessibilityIdentifiers

struct QRCodeReceiveAssetsView: View {
    @ObservedObject var viewModel: QRCodeReceiveAssetsViewModel

    @State private var containerWidth: CGFloat = 0

    var body: some View {
        mainContent
            .padding(.horizontal, 16)
            .id(viewModel.addressInfo.address)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 48) {
            VStack(spacing: 0) {
                Text(viewModel.headerForAddress(with: viewModel.addressInfo))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .padding(.horizontal, 68)
                    .fixedSize(horizontal: false, vertical: true)

                Image(uiImage: viewModel.addressInfo.addressQRImage)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                    .layoutPriority(0)
                    .padding(.top, 32)
                    .padding(.horizontal, 38)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                    .accessibilityIdentifier(QRCodeAccessibilityIdentifiers.qrCodeImage)

                VStack(alignment: .center, spacing: 4) {
                    Text(Localization.commonAddress)
                        .style(Fonts.Bold.callout, color: Colors.Text.tertiary)
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
                .padding(.top, 20)

                if let memoWarningMessage = viewModel.memoWarningMessage {
                    Text(memoWarningMessage)
                        .padding(.top, 12)
                        .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                        .animation(nil, value: viewModel.addressInfo)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                MainButton(
                    title: Localization.commonCopy,
                    icon: .leading(Assets.Glyphs.copy),
                    style: .secondary,
                    action: viewModel.copyToClipboard
                )

                MainButton(
                    title: Localization.commonShare,
                    icon: .leading(Assets.share),
                    style: .secondary,
                    action: viewModel.share
                )
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }
}
