//
//  UserWalletListCellViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class UserWalletListCellViewModel: ObservableObject {
    @Published var balance: String = UserWalletListCellViewModel.defaultBalanceValue
    @Published var numberOfTokens: String? = nil
    @Published var image: UIImage?
    @Published var isSelected = false
    @Published var isBalanceLoading = true

    let userWalletModel: UserWalletModel
    let subtitle: String
    let isMultiWallet: Bool
    let didTapUserWallet: () -> Void
    let totalBalanceProvider: TotalBalanceProviding
    let imageHeight = 30.0

    var userWallet: UserWallet { userWalletModel.userWallet }
    var userWalletId: Data { userWallet.userWalletId }
    var name: String { userWallet.name }
    var isUserWalletLocked: Bool { userWallet.isLocked }

    private let cardImageProvider: CardImageProviding
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        subtitle: String,
        isMultiWallet: Bool,
        isUserWalletLocked: Bool,
        isSelected: Bool,
        totalBalanceProvider: TotalBalanceProviding,
        cardImageProvider: CardImageProviding,
        didTapUserWallet: @escaping () -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.subtitle = subtitle
        self.isMultiWallet = isMultiWallet
        self.isSelected = isSelected
        self.totalBalanceProvider = totalBalanceProvider
        self.cardImageProvider = cardImageProvider
        self.didTapUserWallet = didTapUserWallet

        bind()
        loadImage()

        if isMultiWallet {
            updateNumberOfTokens()
        }
    }

    func onAppear() {
        if !userWalletModel.userWallet.isLocked {
            userWalletModel.initialUpdate()
        }
    }

    private func bind() {
        totalBalanceProvider.totalBalancePublisher()
            .sink { [unowned self] loadingValue in
                switch loadingValue {
                case .loading:
                    self.isBalanceLoading = true
                    self.balance = Self.defaultBalanceValue
                case .loaded(let value):
                    self.isBalanceLoading = false
                    self.balance = value.balance.currencyFormatted(code: value.currencyCode)
                }
            }
            .store(in: &bag)
    }

    private func updateNumberOfTokens() {
        let blockchainsCount = userWalletModel.getSavedEntries().count
        let allTokensCount = blockchainsCount + userWalletModel.getSavedEntries().reduce(0, { $0 + $1.tokens.count })

        numberOfTokens = String.localizedStringWithFormat("token_count".localized, allTokensCount)
    }

    private func loadImage() {
        let artwork: CardArtwork
        if let artworkInfo = userWallet.artwork {
            artwork = .artwork(artworkInfo)
        } else {
            artwork = .notLoaded
        }

        cardImageProvider.loadImage(cardId: userWallet.card.cardId, cardPublicKey: userWallet.card.cardPublicKey, artwork: artwork)
            .sink { [unowned self] image in
                self.image = self.scaleImage(image, newHeight: self.imageHeight * UIScreen.main.scale)
            }
            .store(in: &bag)
    }

    private func scaleImage(_ image: UIImage, newHeight: CGFloat) -> UIImage {
        let scale = newHeight / image.size.height
        let newWidth = image.size.width * scale

        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.draw(in: CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }
}

extension UserWalletListCellViewModel {
    static private let defaultBalanceValue = "$0,000.00"
}
