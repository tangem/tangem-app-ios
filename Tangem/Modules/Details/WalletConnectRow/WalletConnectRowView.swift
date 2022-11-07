//
//  WalletConnectRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectRowViewModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let action: () -> Void

    init(title: String, subtitle: String, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}

struct WalletConnectRowView: View {
    private let viewModel: WalletConnectRowViewModel

    init(viewModel: WalletConnectRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.action) {
            HStack(spacing: 12) {
                Assets.walletConnect
                    .resizable()
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)

                    Text(viewModel.subtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
                .lineLimit(1)

                Spacer()

                Assets.chevron
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
