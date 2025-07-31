//
//  ImportWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct ImportWalletSelectorView: View {
    typealias ViewModel = ImportWalletSelectorViewModel

    @ObservedObject var viewModel: ViewModel

    @State private var screenMaxY: CGFloat = 0
    @State private var scanButtonMinY: CGFloat = 0

    private var buyButtonOffsetY: CGFloat {
        viewModel.isBuyAvailable ? 0 : (screenMaxY - scanButtonMinY + UIApplication.safeAreaInsets.bottom)
    }

    var body: some View {
        content
            .navigationTitle(viewModel.navigationBarTitle)
            .background(Colors.Background.primary.ignoresSafeArea(edges: .vertical))
            .ignoresSafeArea(.keyboard)
            .readGeometry(\.frame.maxY, inCoordinateSpace: .global, bindTo: $screenMaxY)
            .onAppear(perform: viewModel.onAppear)
            .background(Colors.Background.primary)
            .alert(item: $viewModel.error, content: { $0.alert })
            .actionSheet(item: $viewModel.actionSheet, content: { $0.sheet })
            .sheet(item: $viewModel.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}

// MARK: - Subviews

private extension ImportWalletSelectorView {
    var content: some View {
        ZStack(alignment: .top) {
            wallets
                .padding(.top, 32)
                .padding(.horizontal, 16)

            buyButton(viewModel.buyItem)
                .padding(.horizontal, 16)
                .offset(y: buyButtonOffsetY)
                .readGeometry(\.frame.minY, inCoordinateSpace: .global, bindTo: $scanButtonMinY)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .animation(.default, value: viewModel.isBuyAvailable)
        }
    }

    var wallets: some View {
        VStack(spacing: 24) {
            Text(viewModel.screenTitle)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(viewModel.walletItems) { item in
                    walletItem(item)
                }
            }
        }
    }

    func walletItem(_ item: ViewModel.WalletItem) -> some View {
        Button(action: item.action) {
            VStack(alignment: .leading, spacing: 4) {
                walletItemTitle(
                    text: item.title,
                    icon: item.titleIcon,
                    info: item.infoTag
                )

                walletItemSubtitle(text: item.description)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Colors.Field.primary)
            .cornerRadius(14, corners: .allCorners)
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
    }

    func walletItemTitle(
        text: String,
        icon: ImageType?,
        info: ViewModel.InfoTag?
    ) -> some View {
        HStack(spacing: 0) {
            Text(text)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)

            icon.map {
                $0.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.secondary)
                    .padding(.leading, 4)
            }

            info.map {
                infoTag($0)
                    .padding(.leading, 8)
            }
        }
    }

    func walletItemSubtitle(text: String) -> some View {
        Text(text)
            .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    func buyButton(_ item: ViewModel.BuyItem) -> some View {
        HStack(spacing: 0) {
            Text(item.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Spacer(minLength: 22)

            Button(action: viewModel.onBuyTap) {
                Text(item.buttonTitle)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
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
