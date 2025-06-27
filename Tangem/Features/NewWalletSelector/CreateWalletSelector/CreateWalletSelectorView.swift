//
//  CreateWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct CreateWalletSelectorView: View {
    typealias ViewModel = CreateWalletSelectorViewModel

    let viewModel: ViewModel

    var body: some View {
        content
            .padding(.top, 32)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .navigationBarItems(trailing: navigationBarTrailingItem)
            .background(Colors.Background.primary)
    }
}

// MARK: - Content

private extension CreateWalletSelectorView {
    var content: some View {
        VStack(spacing: 24) {
            Text(viewModel.screenTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(Array(viewModel.walletItems.enumerated()), id: \.offset) { _, item in
                    walletItem(item)
                }
            }

            Spacer()

            scan(viewModel.scanItem)
        }
    }
}

// MARK: - Subviews

private extension CreateWalletSelectorView {
    var navigationBarTrailingItem: some View {
        SupportButton(
            title: viewModel.supportButtonTitle,
            height: viewModel.navigationBarHeight,
            isVisible: true,
            isEnabled: true,
            hPadding: 0,
            action: viewModel.onSupportTap
        )
    }

    func walletItem(_ item: ViewModel.WalletItem) -> some View {
        Button(action: item.action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .style(Fonts.Bold.body, color: Colors.Text.primary1)

                    infoTag(item.infoTag)
                }

                Text(item.description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Colors.Field.primary)
            .cornerRadius(14, corners: .allCorners)
        }
    }

    func scan(_ item: ViewModel.ScanItem) -> some View {
        HStack(spacing: 0) {
            Text(item.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Spacer(minLength: 22)

            Button(action: viewModel.onScanTap) {
                HStack(spacing: 4) {
                    Text(item.buttonTitle)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    item.buttonIcon.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Button.primary)
                }
                .padding(.leading, 16)
                .padding(.vertical, 8)
                .padding(.trailing, 12)
                .background(Colors.Button.secondary)
                .cornerRadius(10, corners: .allCorners)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Colors.Field.primary)
        .cornerRadius(14, corners: .allCorners)
    }

    func infoTag(_ item: ViewModel.InfoTag) -> some View {
        Text(item.text)
            .style(Fonts.Bold.caption1, color: item.style.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(item.style.bgColor)
            .cornerRadius(16, corners: .allCorners)
    }
}
