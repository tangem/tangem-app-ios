//
//  WalletConnectNavigationBarView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WalletConnectNavigationBarView: View {
    var title: String?
    var subtitle: String?
    var backButtonAction: (() -> Void)?
    var closeButtonAction: (() -> Void)?

    var body: some View {
        ZStack {
            buttons

            VStack(spacing: .zero) {
                if let title {
                    Text(title)
                        .style(Fonts.Bold.body, color: Colors.Text.primary1)
                }

                if let subtitle {
                    Text(subtitle)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(height: Layout.height)
        .padding(.top, Layout.topPadding)
        .padding(.horizontal, 16)
        .contentShape(.rect)
    }

    private var buttons: some View {
        HStack(spacing: .zero) {
            sfButton("chevron.left", action: backButtonAction)
            Spacer()
            sfButton("multiply", action: closeButtonAction)
        }
    }

    @ViewBuilder
    private func sfButton(_ systemName: String, action: (() -> Void)?) -> some View {
        if let action {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Colors.Icon.secondary)
                    .frame(width: 28, height: 28)
                    .background {
                        Circle()
                            .fill(Colors.Button.secondary)
                    }
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
        }
    }
}

extension WalletConnectNavigationBarView {
    enum Layout {
        /// 8
        static let topPadding: CGFloat = 8
        /// 44
        static let height: CGFloat = 44
    }
}
