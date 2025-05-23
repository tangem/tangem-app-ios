//
//  NFTScanNetworkMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class NFTScanNetworkMapper {
    func mapCollection(
        _ collection: NFTScanNetworkResult.Collection,
        chain: NFTChain,
        ownerAddress: String
    ) throws -> NFTCollection? {
        guard let collectionIdentifier = collection.collection else {
            NFTLogger.warning(
                String(
                    format: "Collection missing required fields: collection %@",
                    String(describing: collection.collection)
                )
            )
            return nil
        }

        let name = collectionIdentifier
        let assets = collection.assets.compactMap { mapAsset($0, chain: chain) }
        let ownerAddress = assets.first?.id.ownerAddress ?? ownerAddress

        return NFTCollection(
            collectionIdentifier: collectionIdentifier,
            chain: chain,
            contractType: .unknown,
            ownerAddress: ownerAddress,
            name: name,
            description: collection.description,
            media: map(collection.logoUrl),
            assetsCount: collection.ownsTotal,
            assets: assets
        )
    }

    func mapAsset(
        _ asset: NFTScanNetworkResult.Asset,
        chain: NFTChain
    ) -> NFTAsset? {
        guard let collectionIdentifier = asset.collection else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: collection %@",
                    String(describing: asset.collection)
                )
            )
            return nil
        }

        let attributes = asset.attributes
        let traits = attributes?.map { attribute in
            NFTAsset.Trait(name: attribute.attributeName, value: attribute.attributeValue)
        } ?? []

        let mediaKind = NFTMediaKindMapper.map(mimetype: asset.contentType)

        let media = asset
            .imageUri?
            .nilIfEmpty
            .flatMap(URL.init(string:))
            .map(NFTIPFSURLConverter.convert(_:))
            .map { NFTMedia(kind: mediaKind, url: $0) }

        let assetMetadata = try? asset.metadataJson?.asDictionary()

        let rarityAttribute = asset.attributes?.first { $0.attributeName == Constants.rarityAttributeName }
        let rarity: NFTAsset.Rarity? = if let rarityAttribute, let percentage = rarityAttribute.percentage {
            makeRarity(from: rarityAttribute, percentage: Double(String(percentage.dropLast()))) // Dropping percent symbol
        } else {
            nil
        }

        return NFTAsset(
            assetIdentifier: asset.tokenUri,
            assetContractAddress: collectionIdentifier,
            chain: chain,
            contractType: .unknown,
            decimalCount: Constants.decimalCount,
            ownerAddress: asset.owner,
            name: asset.name,
            description: assetMetadata?[Constants.assetDescriptionKey] as? String,
            salePrice: nil,
            media: media,
            rarity: rarity,
            traits: traits
        )
    }

    func mapSalePrice(for asset: NFTScanNetworkResult.Asset) -> NFTSalePrice? {
        guard let latestPrice = asset.latestTradePrice else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: latest_trade_price %@",
                    String(describing: asset.latestTradePrice)
                )
            )
            return nil
        }

        let price = NFTSalePrice.Price(value: latestPrice)

        return .init(last: price, lowest: nil, highest: nil)
    }

    private func makeRarity(from attribute: NFTScanNetworkResult.Asset.Attribute, percentage: Double?) -> NFTAsset.Rarity? {
        NFTAsset.Rarity(
            label: attribute.attributeName,
            percentage: percentage,
            rank: Int(attribute.attributeValue)
        )
    }

    private func map(_ urlString: String?) -> NFTMedia? {
        guard
            let url = urlString?
            .nilIfEmpty
            .flatMap(URL.init(string:))
            .map(NFTIPFSURLConverter.convert(_:))
        else {
            return nil
        }

        return NFTMedia(
            kind: NFTMediaKindMapper.map(url),
            url: url
        )
    }
}

private extension NFTScanNetworkMapper {
    enum Constants {
        /// NFTScan doesn't provide decimal count for Solana NFT collections,
        /// so we're using this default value instead.
        static let decimalCount = 0
        static let rarityAttributeName = "Rarity Rank"
        static let assetDescriptionKey = "description"
    }
}
