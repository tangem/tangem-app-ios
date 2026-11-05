//
//  MoralisSolanaNetworkMapper+CollectorCrypt.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

extension MoralisSolanaNetworkMapper {
    enum CollectorCryptRegrouper {
        static func regroup(_ collections: [NFTCollection], ownerAddress: String) -> [NFTCollection] {
            let cards = collections.flatMap { $0.assetsResult.value.filter(isCollectorCryptCard) }

            guard cards.isNotEmpty else {
                return collections
            }

            let otherCollections = collections.compactMap(removingCards)

            let cardCollections = Dictionary(grouping: cards, by: category).map {
                makeCollection(category: $0.key, cards: $0.value, ownerAddress: ownerAddress)
            }

            return otherCollections + cardCollections
        }
    }
}

// MARK: - Private logic

private extension MoralisSolanaNetworkMapper.CollectorCryptRegrouper {
    static func removingCards(from collection: NFTCollection) -> NFTCollection? {
        let assets = collection.assetsResult.value
        let otherAssets = assets.filter { !isCollectorCryptCard($0) }

        guard otherAssets.count < assets.count else {
            return collection
        }

        guard otherAssets.isNotEmpty else {
            return nil
        }

        return NFTCollection(
            collectionIdentifier: collection.id.collectionIdentifier,
            chain: collection.id.chain,
            contractType: collection.contractType,
            ownerAddress: collection.id.ownerAddress,
            name: collection.name,
            description: collection.description,
            media: makeMedia(from: otherAssets),
            assetsCount: otherAssets.count,
            assetsResult: NFTPartialResult(value: otherAssets)
        )
    }

    static func makeCollection(category: String?, cards: [NFTAsset], ownerAddress: String) -> NFTCollection {
        NFTCollection(
            collectionIdentifier: category.map { "\(Constants.collectionIdentifier)_\($0)" } ?? Constants.collectionIdentifier,
            chain: .solana,
            contractType: .unknown,
            ownerAddress: ownerAddress,
            name: category.map { "\($0) (\(Constants.collectionName))" } ?? Constants.collectionName,
            description: nil,
            media: makeMedia(from: cards),
            assetsCount: cards.count,
            assetsResult: NFTPartialResult(value: cards)
        )
    }

    static func makeMedia(from assets: [NFTAsset]) -> NFTMedia? {
        assets.compactMap(NFTAssetMediaExtractor.extractMedia).first
    }

    static func isCollectorCryptCard(_ asset: NFTAsset) -> Bool {
        asset.traits.contains { $0.name == Constants.collectorCryptIdTraitType && $0.value.nilIfEmpty != nil }
    }

    static func category(of asset: NFTAsset) -> String? {
        asset.traits.first { $0.name == Constants.categoryTraitType }?.value.nilIfEmpty
    }
}

// MARK: - Constants

private extension MoralisSolanaNetworkMapper.CollectorCryptRegrouper {
    enum Constants {
        static let collectorCryptIdTraitType = "Collector Crypt ID"
        static let categoryTraitType = "Category"
        static let collectionName = "Collector Crypt"
        static let collectionIdentifier = "collector_crypt"
    }
}
