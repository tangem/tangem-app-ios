//
//  AddWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct AddWalletSelectorView: View {
    typealias ViewModel = AddWalletSelectorViewModel

    @ObservedObject var viewModel: ViewModel

    @State private var screenMaxY: CGFloat = 0
    @State private var buyButtonMinY: CGFloat = 0

    private var buyButtonOffsetY: CGFloat {
        viewModel.isBuyAvailable ? 0 : (screenMaxY - buyButtonMinY + UIApplication.safeAreaInsets.bottom)
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
            .readGeometry(\.frame.maxY, inCoordinateSpace: .global, bindTo: $screenMaxY)
            .navigationBarItems(trailing: navigationBarTrailingItem)
            .onFirstAppear(perform: viewModel.onAppear)
            .background(Colors.Background.secondary)
            .alert(item: $viewModel.alert, content: { $0.alert })
    }
}

// MARK: - Content

private extension AddWalletSelectorView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Text(viewModel.screenTitle)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 8) {
                    ForEach(viewModel.walletItems) { item in
                        walletItem(item)
                    }
                }
            }
            .padding(.top, 32)
        }
        .safeAreaInset(edge: .bottom, spacing: 16) {
            buyButton(item: viewModel.buyItem)
                .bottomPaddingIfZeroSafeArea()
                .offset(y: buyButtonOffsetY)
                .readGeometry(\.frame.minY, inCoordinateSpace: .global, bindTo: $buyButtonMinY)
                .animation(.default, value: viewModel.isBuyAvailable)
        }
    }
}

// MARK: - Subviews

private extension AddWalletSelectorView {
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
            VStack(alignment: .leading, spacing: 12) {
                walletDescription(item: item.description)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Colors.Background.primary)
            .cornerRadius(14, corners: .allCorners)
        }
    }

    func walletDescription(item: ViewModel.WalletDescriptionItem) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                WrappingHStack(
                    alignment: .leading,
                    horizontalSpacing: 8,
                    verticalSpacing: 4
                ) {
                    walletDescriptionHeader(title: item.title, badge: item.badge)
                }

                Text(item.subtitle)
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Assets.chevronRightWithOffset24.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Colors.Text.tertiary)
                .frame(width: 24, height: 24)
        }
    }

    func walletDescriptionHeader(title: String, badge: BadgeView.Item?) -> some View {
        Group {
            Text(title)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            badge.map(BadgeView.init)
        }
    }

    func buyButton(item: ViewModel.BuyItem) -> some View {
        HStack(spacing: 0) {
            Text(item.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 22)

            Button(action: item.buttonAction) {
                Text(item.buttonTitle)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Colors.Button.secondary)
                    .cornerRadius(24, corners: .allCorners)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .cornerRadius(14, corners: .allCorners)
    }
}
