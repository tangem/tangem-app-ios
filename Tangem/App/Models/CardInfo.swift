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

    #if !CLIP
//    var isTestnet: Bool {
//        return card.isTestnet || (defaultBlockchain?.isTestnet ?? false)
//    }

    var defaultStorageEntry: StorageEntry? {
        guard let defaultBlockchain = defaultBlockchain else {
            return nil
        }

        let derivationPath = defaultBlockchain.derivationPath(for: .legacy)
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: derivationPath)
        let tokens = defaultToken.map { [$0] } ?? []
        return StorageEntry(blockchainNetwork: network, tokens: tokens)
    }

    #endif

    var artworkInfo: ArtworkInfo? {
        switch artwork {
        case .notLoaded, .noArtwork: return nil
        case .artwork(let artwork): return artwork
        }
    }

    var isMultiWallet: Bool {

        return true //[REDACTED_TODO_COMMENT]
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
