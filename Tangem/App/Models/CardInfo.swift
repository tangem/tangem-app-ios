//
//  CardInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

#if !CLIP
import BlockchainSdk
#endif

struct CardInfo {
    var card: Card
    var walletData: DefaultWalletData
    var artwork: CardArtwork = .notLoaded
    var derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]] = [:]
    var primaryCard: PrimaryCard? = nil

    var imageLoadDTO: ImageLoadDTO {
        ImageLoadDTO(cardId: card.cardId,
                     cardPublicKey: card.cardPublicKey,
                     artwotkInfo: artworkInfo)
    }

    var cardIdFormatted: String {
        if case let .twin(twinData) = walletData {
            return AppTwinCardIdFormatter.format(cid: card.cardId, cardNumber: twinData.series.number)
        } else {
            return AppCardIdFormatter(cid: card.cardId).formatted()
        }
    }

    #if !CLIP
//    var isTestnet: Bool {
//        return card.isTestnet || (defaultBlockchain?.isTestnet ?? false)
//    }


    #endif

    var artworkInfo: ArtworkInfo? {
        switch artwork {
        case .notLoaded, .noArtwork: return nil
        case .artwork(let artwork): return artwork
        }
    }
}

enum CardArtwork: Equatable {
    case notLoaded
    case noArtwork
    case artwork(ArtworkInfo)
}

struct ImageLoadDTO: Equatable {
    let cardId: String
    let cardPublicKey: Data
    let artwotkInfo: ArtworkInfo?
}
