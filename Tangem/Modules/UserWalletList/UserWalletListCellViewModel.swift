//
//  UserWalletListCellViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import Combine

class UserWalletListCellViewModel: ObservableObject, Identifiable {
    @Injected(\.cardImageLoader) var imageLoader: CardImageLoaderProtocol

    let account: Account
    let subtitle: String
    let numberOfTokens: String?
    var cardImage: UIImage?

    private var bag: Set<AnyCancellable> = []

    init(account: Account, subtitle: String, numberOfTokens: Int?) {
        self.account = account
        self.subtitle = subtitle
        if let numberOfTokens = numberOfTokens {
            #warning("l10n")
            self.numberOfTokens = "\(numberOfTokens) tokens"
        } else {
            self.numberOfTokens = nil
        }

        imageLoader.loadImage(cid: account.card.cardId, cardPublicKey: account.card.cardPublicKey, artworkInfo: account.artwork)
            .sink { [weak self] (image, _) in
                self?.cardImage = image
            }
            .store(in: &bag)
    }
}
