//
//  NewAuthView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct NewAuthView: View {
    typealias ViewModel = NewAuthViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        stateView
            .animation(.default, value: viewModel.state)
            .alert(item: $viewModel.error, content: { $0.alert })
            .actionSheet(item: $viewModel.actionSheet, content: { $0.sheet })
            .background(Colors.Background.primary.ignoresSafeArea())
            .ignoresSafeArea(.keyboard)
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
    }
}

// MARK: - States

private extension NewAuthView {
    var stateView: some View {
        ZStack {
            switch viewModel.state {
            case .locked:
                LockView(usesNamespace: false)
                    .transition(.opacity)
            case .unlocked(let item):
                unlockedView(item: item)
                    .transition(.opacity)
            case .none:
                EmptyView()
            }
        }
    }

    func unlockedView(item: ViewModel.UnlockedStateItem) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 32) {
                topBar(item: item.addWallet)

                infoView(item: item.info)
                    .padding(.horizontal, 16)

                walletsView(items: item.wallets)
                    .padding(.horizontal, 16)
                    .ignoresSafeArea(edges: .bottom)
            }

            item.unlock.map {
                unlockButton(item: $0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
    }
}

// MARK: - WalletsState subviews

private extension NewAuthView {
    func topBar(item: ViewModel.AddWalletItem) -> some View {
        HStack {
            Assets.newTangemLogo.image
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Colors.Icon.primary1)
                .frame(width: 86, height: 18)

            Spacer()

            Button(action: item.action) {
                Text(item.title)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    func infoView(item: ViewModel.InfoItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(item.description)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func walletsView(items: [ViewModel.WalletItem]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(items) {
                    walletView(item: $0)
                }
            }
        }
    }

    func walletView(item: ViewModel.WalletItem) -> some View {
        Button(action: item.action) {
            HStack(spacing: 12) {
                item.icon.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 0) {
                    Text(item.name)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    HStack(spacing: 4) {
                        Text(item.description)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                        if item.isSecured {
                            Assets.stakingLockIcon.image
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Colors.Icon.informative)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Colors.Field.primary)
            .cornerRadius(14, corners: .allCorners)
        }
    }

    func unlockButton(item: ViewModel.UnlockItem) -> some View {
        Button(action: item.action) {
            Text(item.title)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Colors.Button.secondary)
                .cornerRadius(14, corners: .allCorners)
        }
    }
}
