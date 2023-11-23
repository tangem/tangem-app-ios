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
        userWalletModel.userWalletId
    }

    var name: String {
        userWalletModel.config.cardName
    }

    let didTapWallet: (UserWalletId) -> Void
    let imageHeight = 30.0

    private let userWalletModel: UserWalletModel

    private let cardImageProvider: CardImageProviding
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        isSelected: Bool,
        cardImageProvider: CardImageProviding,
        didTapWallet: @escaping (UserWalletId) -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.isSelected = isSelected
        self.cardImageProvider = cardImageProvider
        self.didTapWallet = didTapWallet

        loadImage()
    }

    private func loadImage() {
        userWalletModel
            .cardImagePublisher
            .sink { [weak self] loadResult in
                guard let self else { return }

                image = scaleImage(loadResult.uiImage, newHeight: imageHeight * UIScreen.main.scale)
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
