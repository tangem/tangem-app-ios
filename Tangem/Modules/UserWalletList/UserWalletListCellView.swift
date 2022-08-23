//
//  UserWalletListCellView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListCellView: View {
    @ObservedObject var model: CardViewModel
    let isSelected: Bool
    let didTapUserWallet: (UserWallet) -> Void

    private let selectionIconSize: CGSize = .init(width: 14, height: 14)
    private let selectionIconBorderWidth: Double = 2

    var body: some View {
        HStack(spacing: 12) {
            if let image = model.cardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 50, minHeight: 30, maxHeight: 30)
                    .overlay(selectionIcon.offset(x: 4, y: -4), alignment: .topTrailing)
            } else {
                Color.tangemGrayLight4
                    .transition(.opacity)
                    .opacity(0.5)
                    .cornerRadius(3)
                    .frame(width: 50, height: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(model.userWallet.name)
                    .style(Fonts.Bold.subheadline, color: isSelected ? Colors.Text.accent : Colors.Text.primary1)

                Text(model.subtitle)
                    .font(Font.footnote)
                    .foregroundColor(Colors.Text.tertiary)
            }

            Spacer()

            if !model.isUserWalletLocked {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(model.totalBalance ?? "")
                        .font(Font.subheadline)
                        .foregroundColor(Colors.Text.primary1)

                    Text(model.numberOfTokens ?? "")
                        .font(Font.footnote)
                        .foregroundColor(Colors.Text.tertiary)
                }
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .background(Colors.Background.primary)
        .onTapGesture {
            didTapUserWallet(model.userWallet)
        }
    }

    @ViewBuilder
    private var selectionIcon: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: selectionIconSize.width, height: selectionIconSize.height)
                .foregroundColor(Colors.Text.accent)
                .background(
                    Colors.Background.primary
                        .clipShape(Circle())
                        .frame(size: selectionIconSize + CGSize(width: 2 * selectionIconBorderWidth, height: 2 * selectionIconBorderWidth))
                )
        }
    }
}
