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
    var walletData: WalletData?
    var artwork: CardArtwork = .notLoaded
    var twinCardInfo: TwinCardInfo?
    var isTangemNote: Bool
    var isTangemWallet: Bool
    var derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]] = [:]
    var primaryCard: PrimaryCard? = nil

    var imageLoadDTO: ImageLoadDTO {
        ImageLoadDTO(cardId: card.cardId,
                     cardPublicKey: card.cardPublicKey,
                     artwotkInfo: artworkInfo)
    }

    #if !CLIP
    var isTestnet: Bool {
        return card.isTestnet || (defaultBlockchain?.isTestnet ?? false)
    }

    var isSaltPay: Bool {
        false // Temp solution, we don't have information so far
    }

    var defaultBlockchain: Blockchain? {
        guard let walletData = walletData else { return nil }

        guard let curve = isTangemNote ? EllipticCurve.secp256k1 : card.supportedCurves.first else {
            return nil
        }

        let blockchainName = isTangemNote ? (walletData.blockchain.lowercased() == "binance" ? "bsc" : walletData.blockchain)
            : walletData.blockchain

        return Blockchain.from(blockchainName: blockchainName, curve: curve)
    }

    var defaultToken: BlockchainSdk.Token? {
        guard let token = walletData?.token, defaultBlockchain != nil else { return nil }

        return Token(name: token.name,
                     symbol: token.symbol,
                     contractAddress: token.contractAddress,
                     decimalCount: token.decimals)
    }

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
        if isTangemNote {
            return false
        }

        if card.isTwinCard {
            return false
        }

        if card.isStart2Coin {
            return false
        }

        if card.firmwareVersion.major < 4,
           !card.supportedCurves.contains(.secp256k1) {
            return false
        }

        return true
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
