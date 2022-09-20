//
//  UserWalletListCellView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class UserWalletListCellViewModel: ObservableObject {
    @Published var balance: String = ""
    @Published var image: UIImage?

    let userWallet: UserWallet
    let subtitle: String
    let numberOfTokens: String?
    let isSelected: Bool
    let didTapUserWallet: () -> Void

    var userWalletId: Data { userWallet.userWalletId }
    var name: String { userWallet.name }
    var isUserWalletLocked: Bool { userWallet.isLocked }

    private let totalBalanceProvider: TotalBalanceProviding
    private let cardImageProvider: CardImageProviding

    private var totalBalanceBag: AnyCancellable?
    private var cardImageBag: AnyCancellable?

    init(
        userWallet: UserWallet,
        subtitle: String,
        numberOfTokens: String?,
        isUserWalletLocked: Bool,
        isSelected: Bool,
        totalBalanceProvider: TotalBalanceProviding,
        cardImageProvider: CardImageProviding,
        didTapUserWallet: @escaping () -> Void
    ) {
        self.userWallet = userWallet
        self.subtitle = subtitle
        self.numberOfTokens = numberOfTokens
        self.isSelected = isSelected
        self.totalBalanceProvider = totalBalanceProvider
        self.cardImageProvider = cardImageProvider
        self.didTapUserWallet = didTapUserWallet

        bind()
    }

    func bind() {
        totalBalanceBag = totalBalanceProvider.totalBalancePublisher()
            .compactMap { $0.value }
            .sink { [unowned self] balance in
                self.balance = balance.balance.currencyFormatted(code: balance.currency.code)
            }
    }

    func updateTotalBalance() {
        totalBalanceProvider.updateTotalBalance()
    }

    func loadImage() {
        cardImageBag = cardImageProvider.loadImage(cardId: userWallet.card.cardId, cardPublicKey: userWallet.card.cardPublicKey)
            .sink { [unowned self] image in
                self.image = image
            }
    }
}

struct UserWalletListCellView: View {
    static let hardcodedHeight = 67.0

    @ObservedObject private var viewModel: UserWalletListCellViewModel

    init(viewModel: UserWalletListCellViewModel) {
        self.viewModel = viewModel
    }

    private let selectionIconSize: CGSize = .init(width: 14, height: 14)
    private let selectionIconBorderWidth: Double = 2

    var body: some View {
        HStack(spacing: 12) {
            if let image = viewModel.image {
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
                Text(viewModel.name)
                    .style(Fonts.Bold.subheadline, color: viewModel.isSelected ? Colors.Text.accent : Colors.Text.primary1)

                Text(viewModel.subtitle)
                    .font(Font.footnote)
                    .foregroundColor(Colors.Text.tertiary)
            }

            Spacer()

            if !viewModel.isUserWalletLocked {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.balance)
                        .font(Font.subheadline)
                        .foregroundColor(Colors.Text.primary1)

                    Text(viewModel.numberOfTokens ?? "")
                        .font(Font.footnote)
                        .foregroundColor(Colors.Text.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: Self.hardcodedHeight)
        .contentShape(Rectangle())
        .background(Colors.Background.primary)
        .onTapGesture {
            viewModel.didTapUserWallet()
        }
    }

    @ViewBuilder
    private var selectionIcon: some View {
        if viewModel.isSelected {
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
