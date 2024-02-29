//
//  WalletSelectorItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletSelectorItemView: View {
    @ObservedObject var viewModel: WalletSelectorItemViewModel

    private let maxImageWidth = 50.0

    var body: some View {
        HStack(spacing: 12) {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxImageWidth, minHeight: viewModel.imageHeight, maxHeight: viewModel.imageHeight)
            } else {
                SkeletonView()
                    .cornerRadius(3)
                    .frame(width: maxImageWidth, height: viewModel.imageHeight)
            }

            Text(viewModel.name)
                .lineLimit(1)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Spacer(minLength: 0)

            if viewModel.isSelected {
                Assets.check.image
                    .frame(width: 20, height: 20)
                    .foregroundColor(Colors.Icon.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 19)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapWallet(viewModel.userWalletId)
        }
    }
}

struct WalletSelectorItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WalletSelectorItemView(viewModel: .init(
                userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
                name: FakeUserWalletModel.wallet3Cards.config.cardName,
                cardImagePublisher: FakeUserWalletModel.wallet3Cards.cardImagePublisher,
                isSelected: true,
                didTapWallet: { _ in }
            )
            )

            WalletSelectorItemView(viewModel: .init(
                userWalletId: FakeUserWalletModel.wallet3Cards.userWalletId,
                name: FakeUserWalletModel.wallet3Cards.config.cardName,
                cardImagePublisher: FakeUserWalletModel.wallet3Cards.cardImagePublisher,
                isSelected: false,
                didTapWallet: { _ in }
            )
            )
        }
    }
}
