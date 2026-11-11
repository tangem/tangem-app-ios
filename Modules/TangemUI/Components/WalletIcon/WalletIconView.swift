//
//  WalletIconView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct WalletIconView: View {
    private let content: WalletIconContent?
    private let width: CGFloat

    public init(content: WalletIconContent?, width: CGFloat) {
        self.content = content
        self.width = width
    }

    public var body: some View {
        Group {
            switch content {
            case .image(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

            case .iconWithBackground(let iconWithBackground):
                iconWithBackgroundView(iconWithBackground)

            case .none:
                Shimmer()
                    .variant(.custom(width: width, height: (width * 0.61).rounded(), cornerRadius: 3))
            }
        }
        .frame(width: width, height: width)
    }

    private func iconWithBackgroundView(_ content: WalletIconContent.IconWithBackground) -> some View {
        content.icon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: width * Self.iconToWidthRatio, height: width * Self.iconToWidthRatio)
            .foregroundStyle(content.iconColor)
            .frame(width: width, height: width * Self.backgroundHeightToWidthRatio)
            .background(content.backgroundColor, in: .capsule)
            .accessibilityHidden(true)
    }
}

private extension WalletIconView {
    static let backgroundHeightToWidthRatio: CGFloat = 28 / 40
    static let iconToWidthRatio: CGFloat = 16 / 40
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        WalletIconView(content: .iconWithBackground(.mobileWallet), width: 40)
        WalletIconView(content: nil, width: 40)
    }
}
