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
    @Published var balance: String = "$0,000.00"
    @Published var image: UIImage?
    @Published var isSelected = false
    @Published var isBalanceLoading = true

    let userWalletModel: UserWalletModel
    var userWallet: UserWallet { userWalletModel.userWallet }
    let subtitle: String
    let numberOfTokens: String?
    let didTapUserWallet: () -> Void

    var userWalletId: Data { userWallet.userWalletId }
    var name: String { userWallet.name }
    var isUserWalletLocked: Bool { userWallet.isLocked }

    let totalBalanceProvider: TotalBalanceProviding
    private let cardImageProvider: CardImageProviding

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        subtitle: String,
        numberOfTokens: String?,
        isUserWalletLocked: Bool,
        isSelected: Bool,
        totalBalanceProvider: TotalBalanceProviding,
        cardImageProvider: CardImageProviding,
        didTapUserWallet: @escaping () -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.subtitle = subtitle
        self.numberOfTokens = numberOfTokens
        self.isSelected = isSelected
        self.totalBalanceProvider = totalBalanceProvider
        self.cardImageProvider = cardImageProvider
        self.didTapUserWallet = didTapUserWallet

        bind()
        loadImage()
    }

    func bind() {
        totalBalanceProvider.totalBalancePublisher()
            .compactMap { $0.value }
            .sink { [unowned self] balance in
                self.balance = balance.balance.currencyFormatted(code: balance.currency.code)
            }
            .store(in: &bag)

        userWalletModel.subscribeToWalletModels()
            .map { walletModels in
                self.isBalanceLoading = true

                return walletModels
                    .map { $0.walletDidChange }
                    .combineLatest()
                    .map { _ in walletModels }
                    // Update total balance only after all models successfully loaded
                    .filter { $0.allConforms { !$0.state.isLoading } }
            }
            .switchToLatest()
            .sink { [unowned self] _ in
                self.totalBalanceProvider.updateTotalBalance()
                self.isBalanceLoading = false
            }
            .store(in: &bag)

        update()
    }

    private func update() {
        userWalletModel.updateAndReloadWalletModels()
    }

    private func loadImage() {
        cardImageProvider.loadImage(cardId: userWallet.card.cardId, cardPublicKey: userWallet.card.cardPublicKey)
            .sink { [unowned self] image in
                self.image = image
            }
            .store(in: &bag)
    }
}

struct UserWalletListCellView: View {
    @ObservedObject private var viewModel: UserWalletListCellViewModel

    init(viewModel: UserWalletListCellViewModel) {
        self.viewModel = viewModel
    }

    private let selectionIconSize: CGSize = .init(width: 14, height: 14)
    private let selectionIconBorderWidth: Double = 2

    var body: some View {
        HStack(spacing: 12) {
            cardImage
                .overlay(selectionIcon.offset(x: 4, y: -4), alignment: .topTrailing)

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
                        .skeletonable(isShown: viewModel.isBalanceLoading, radius: 6)

                    Text(viewModel.numberOfTokens ?? "")
                        .font(Font.footnote)
                        .foregroundColor(Colors.Text.tertiary)
                }
            } else {
                lockIcon
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 67)
        .contentShape(Rectangle())
        .background(Colors.Background.primary)
        .onTapGesture {
            viewModel.didTapUserWallet()
        }
    }

    @ViewBuilder
    private var cardImage: some View {
        if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 50, minHeight: 30, maxHeight: 30)
        } else {
            Color.tangemGrayLight4
                .transition(.opacity)
                .opacity(0.5)
                .cornerRadius(3)
                .frame(width: 50, height: 30)
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

    @ViewBuilder
    private var lockIcon: some View {
        Assets.lock
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Colors.Background.secondary)
            .cornerRadius(10)
    }
}
