//
//  WCWalletSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WCWalletSelectorView: View {
    @StateObject private var viewModel: WCWalletSelectorViewModel
    
    init(input: WCWalletSelectorInput) {
        _viewModel = .init(wrappedValue: .init(input: input))
    }

    var body: some View {
        content
    }

    private var content: some View {
        VStack(spacing: 12) {
            header
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.userWalletModels, id: \.userWalletId) { userWalletModel in
                    WCWalletRowView(
                        viewModel: .init(
                            userWallet: userWalletModel,
                            tapAction: { viewModel.handleViewAction(.selectWallet(userWalletModel)) }
                        )
                    )
                    .padding(.init(top: 14, leading: 16, bottom: 14, trailing: 16))
                    .background { selectionBorder(userWalletModel.userWalletId.stringValue) }
                    
                    if viewModel.checkNotLastListItem(userWalletModel) {
                        Separator(height: .minimal, color: Colors.Stroke.primary)
                            .padding(.leading, 62)
                    }
                }
            }
            .padding(.init(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
    }

    private var header: some View {
        WalletConnectNavigationBarView(
            title: "Choose wallet",
            backButtonAction: { viewModel.handleViewAction(.returnToConnectionDetails) }
        )
    }

    private func backButton() -> some View {
        Button(
            action: { viewModel.handleViewAction(.returnToConnectionDetails) },
            label: {
                ZStack {
                    Circle()
                        .foregroundStyle(Colors.Button.secondary)
                        .frame(size: .init(bothDimensions: 28))
                    Assets.WalletConnect.chevronRight.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.secondary)
                        .rotationEffect(.degrees(180))
                }
            }
        )
    }

    @ViewBuilder
    private func selectionBorder(_ userWalletModelId: String) -> some View {
        if viewModel.checkSelectedWallet(userWalletModelId) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style: .init(lineWidth: 1))
                    .foregroundStyle(Colors.Text.accent)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style: .init(lineWidth: 2))
                    .foregroundStyle(Colors.Text.accent.opacity(0.2))
                    .padding(-1)
            }
        }
    }
}
