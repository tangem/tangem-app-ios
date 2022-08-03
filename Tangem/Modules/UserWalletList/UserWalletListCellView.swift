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

    private let selectedIconSize: CGSize = .init(width: 14, height: 14)
    private let selectedIconBorderWidth: Double = 2

    var body: some View {
        HStack(spacing: 12) {
            if let image = model.cardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(minHeight: 30, maxHeight: 30)
                    .overlay(selectedIcon.offset(x: 4, y: -4), alignment: .topTrailing)
            } else {
                Color.tangemGrayLight4
                    .transition(.opacity)
                    .opacity(0.5)
                    .cornerRadius(3)
                    .frame(width: 50, height: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(model.userWallet.name)
                    .font(Font.subheadline.bold)
                    .foregroundColor(isSelected ? Colors.Text.accent : Colors.Text.primary1)

                Text(model.subtitle)
                    .font(Font.footnote)
                    .foregroundColor(Colors.Text.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(model.totalBalance ?? "999.99")
                    .font(Font.subheadline)
                    .foregroundColor(Colors.Text.primary1)
                    .skeletonable(isShown: model.totalBalanceLoading)

                Text(model.numberOfTokens ?? "")
                    .font(Font.footnote)
                    .foregroundColor(Colors.Text.tertiary)
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
    private var selectedIcon: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: selectedIconSize.width, height: selectedIconSize.height)
                .foregroundColor(Colors.Text.accent)
                .background(
                    Colors.Background.primary
                        .clipShape(Circle())
                        .frame(size: selectedIconSize + CGSize(width: 2 * selectedIconBorderWidth, height: 2 * selectedIconBorderWidth))
                )
        }
    }
}

struct UserWalletListCellView_Previews: PreviewProvider {
    static var previews: some View {
        UserWalletListCellView(model: .init(cardInfo: UserWallet.wallet(index: 0).cardInfo()), isSelected: true) { _ in }
    }
}
