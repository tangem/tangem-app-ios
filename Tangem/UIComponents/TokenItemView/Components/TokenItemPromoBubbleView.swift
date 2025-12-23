//
//  PromoBubbleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TokenItemPromoBubbleView: View {
    let viewModel: TokenItemPromoBubbleViewModel
    let position: Position

    var body: some View {
        Button(action: { viewModel.onTap() }) {
            label
        }
    }

    private var label: some View {
        HStack(spacing: 8) {
            viewModel.leadingImage

            Text(viewModel.message)
                .style(Fonts.Bold.caption1, color: Colors.Text.secondary)

            Spacer()

            Assets.cross16.image
                .onTapGesture {
                    viewModel.onDismiss()
                }
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 14))
        .background(Colors.Control.unchecked)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.top, position == .top ? 14 : 0)
        .background(background)
    }

    private var background: some View {
        Colors.Background.primary
            .cornerRadiusContinuous(
                topLeadingRadius: position == .top ? 14 : 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: position == .top ? 14 : 0
            )
    }
}

extension TokenItemPromoBubbleView {
    enum Position {
        case top
        case normal
    }
}

struct TokenItemPromoBubbleViewModel {
    let id: WalletModelId
    let leadingImage: Image
    let message: String
    let onDismiss: () -> Void
    let onTap: () -> Void
}
