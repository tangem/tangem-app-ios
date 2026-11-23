//
//  MCPConnectionRequestUserWalletSelectorRowView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MCPConnectionRequestUserWalletSelectorRowView: View {
    @ObservedObject var viewModel: MCPConnectionRequestUserWalletSelectorRowViewModel

    var body: some View {
        Row(title: viewModel.state.title, subtitle: viewModel.state.subtitle.text)
            .subtitleAccessory {
                if viewModel.state.subtitle == .loading {
                    Shimmer()
                        .variant(.text(style: .caption))
                }
            }
            .onTap { viewModel.handle(action: .viewTapped) }
            .start { image }
            .end { Checkmark.Label(isChecked: viewModel.state.isSelected) }
            .disabled(viewModel.state.isDisabled)
            .task {
                viewModel.handle(action: .viewDidLoad)
            }
    }

    @ViewBuilder
    private var image: some View {
        switch viewModel.state.image {
        case .loading:
            Shimmer()
                .frame(width: 40, height: 26)
                .clipShape(.rect(cornerRadius: 4))

        case .content(let uiImage):
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 26)
                .clipShape(.rect(cornerRadius: 4))

        case .mobileWallet:
            WalletIconView(content: .iconWithBackground(.mobileWallet), width: 40)
        }
    }
}
