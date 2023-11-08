//
//  WalletSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class WalletSelectorItemViewModel: ObservableObject, Identifiable {
    @Published var image: UIImage? = nil
    @Published var isSelected: Bool = false

    var id: UserWalletId {
        userWallet.userWalletId
    }

    var name: String {
        userWallet.config.cardName
    }

    let didTapWallet: (UserWalletId) -> Void
    let imageHeight = 30.0
    let userWallet: UserWalletModel

    private let cardImageProvider: CardImageProviding
    private var bag: Set<AnyCancellable> = []

    init(
        userWallet: UserWalletModel,
        isSelected: Bool,
        cardImageProvider: CardImageProviding,
        didTapWallet: @escaping (UserWalletId) -> Void
    ) {
        self.userWallet = userWallet
        self.isSelected = isSelected
        self.cardImageProvider = cardImageProvider
        self.didTapWallet = didTapWallet

        loadImage()
    }

    private func loadImage() {
//        let artwork: CardArtwork
//        if let artworkInfo = userWallet.config...artwork {
//            artwork = .artwork(artworkInfo)
//        } else {
//            artwork = .notLoaded
//        }

//        cardImageProvider.loadImage(
//            cardId: userWallet.config.cardId,
//            cardPublicKey: userWallet.card.cardPublicKey,
//            artwork: artwork
//        )
//        .sink { [weak self] loadResult in
//            guard let self else { return }
//
//            image = scaleImage(loadResult.uiImage, newHeight: imageHeight * UIScreen.main.scale)
//        }
//        .store(in: &bag)
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
