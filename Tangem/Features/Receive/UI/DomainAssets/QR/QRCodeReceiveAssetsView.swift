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

struct QRCodeReceiveAssetsView: View {
    @ObservedObject var viewModel: QRCodeReceiveAssetsViewModel

    @State private var containerWidth: CGFloat = 0

    var body: some View {
        mainContent
            .onAppear(perform: viewModel.onViewAppear)
            .id(viewModel.addressInfo.address)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(viewModel.headerForAddress(with: viewModel.addressInfo))
                    .multilineTextAlignment(.center)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .padding(.horizontal, 84)
                    .padding(.top, 4)
                    .animation(nil, value: viewModel.addressInfo)

                Image(uiImage: viewModel.addressInfo.addressQRImage)
                    .resizable()
                    .frame(width: 220, height: 220)
                    .padding(.top, 18)

                VStack(alignment: .center, spacing: 4) {
                    Text(Localization.commonAddress)
                        .padding(.horizontal, 32)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Button {
                        viewModel.copyToClipboard()
                    } label: {
                        SUILabel(viewModel.stringForAddress(viewModel.addressInfo.address))
                            .padding(.horizontal, 32)
                            .contentShape(Rectangle())
                            .animation(nil, value: viewModel.addressInfo)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                if let memoWarningMessage = viewModel.memoWarningMessage {
                    Text(memoWarningMessage)
                        .padding(.top, 12)
                        .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                        .animation(nil, value: viewModel.addressInfo)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .frame(width: containerWidth)

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
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .readGeometry(\.size.width, bindTo: $containerWidth)
    }
}
