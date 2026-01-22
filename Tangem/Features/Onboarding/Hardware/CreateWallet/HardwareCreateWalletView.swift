//
//  HardwareCreateWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct HardwareCreateWalletView: View {
    typealias ViewModel = HardwareCreateWalletViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .allowsHitTesting(!viewModel.isScanning)
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .alert(item: $viewModel.alert, content: { $0.alert })
    }
}

// MARK: - Subviews

private extension HardwareCreateWalletView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                logo

                Text(viewModel.screenTitle)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 20)

                infos(items: viewModel.infoItems)
                    .padding(.top, 32)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 32)
        }
        .safeAreaInset(edge: .bottom, spacing: 16) {
            actionButtons
                .bottomPaddingIfZeroSafeArea()
        }
    }

    var logo: some View {
        Assets.tangemIconMedium.image
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 30)
            .foregroundStyle(Colors.Icon.primary1)
            .padding(.vertical, 22)
            .padding(.horizontal, 24)
            .background(
                Colors.Field.focused
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            )
    }

    func infos(items: [ViewModel.InfoItem]) -> some View {
        VStack(spacing: 28) {
            ForEach(items) { item in
                HStack(spacing: 16) {
                    item.icon.image
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Colors.Icon.primary1)
                        .frame(width: 24, height: 24)
                        .padding(10)
                        .background(
                            Colors.Control.unchecked
                                .clipShape(Circle())
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                        Text(item.subtitle)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    var actionButtons: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.buyButtonTitle,
                style: .secondary,
                action: viewModel.onBuyTap
            )

            MainButton(
                title: viewModel.scanButtonTitle,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                isLoading: viewModel.isScanning,
                action: viewModel.onScanTap
            )
            .confirmationDialog(viewModel: $viewModel.scanTroubleshootingDialog)
        }
    }
}
