//
//  MainQRScanTokenSelectorWalletHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MainQRScanTokenSelectorWalletHeaderView: View {
    let walletName: String
    let isOpen: Bool
    let toggleAction: () -> Void

    var body: some View {
        Button(action: toggleAction) {
            HStack(spacing: .zero) {
                Text(walletName)
                    .style(Fonts.Bold.headline, color: Colors.Text.primary1)

                Spacer(minLength: Constants.horizontalSpacing)

                chevronButton
            }
            .padding(.horizontal, Constants.horizontalSpacing)
            .padding(.vertical, 2.0)
        }
    }

    private var chevronButton: some View {
        Button(action: {}) {
            Assets.Glyphs.chevronDownNew.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
                .frame(width: 20.0, height: 20.0)
                .frame(width: 28.0, height: 28.0)
                .background {
                    Circle()
                        .fill(Colors.Button.secondary)
                }
        }
        .rotationEffect(.degrees(isOpen ? 0.0 : 180.0))
        .allowsHitTesting(false)
        .animation(.spring(duration: 0.2), value: isOpen)
    }
}

private extension MainQRScanTokenSelectorWalletHeaderView {
    enum Constants {
        static let horizontalSpacing = 8.0
    }
}
