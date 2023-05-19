//
// Copyright © 2023 m3g0byt3
//

import Foundation

struct CardAppearance: Equatable {
    private enum Constants {
        static let defaultArtwork = CardArtwork.notLoaded
    }

    var name: String
    var artwork: CardArtwork = Constants.defaultArtwork
}

extension CardAppearance {
    init(
        userWallet: UserWallet
    ) {
        self.init(
            name: userWallet.name,
            artwork: userWallet.artwork.map(CardArtwork.artwork) ?? Constants.defaultArtwork
        )
    }
}
