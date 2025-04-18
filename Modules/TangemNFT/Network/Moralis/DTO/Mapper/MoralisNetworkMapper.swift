//
//  MoralisNetworkMapper.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MoralisNetworkMapper {
    let chain: NFTChain

    func map(collections: [MoralisNetworkResult.EVMNFTCollection], ownerAddress: String) -> [NFTCollection] {
        return collections.compactMap { collection in
            guard
                let collectionIdentifier = collection.tokenAddress,
                let name = collection.name,
                let assetsCount = collection.count
            else {
                NFTLogger.warning(
                    String(
                        format: "Collection missing required fields: token_address %@, name %@, count %@",
                        String(describing: collection.tokenAddress),
                        String(describing: collection.name),
                        String(describing: collection.count)
                    )
                )
                return nil
            }

            let contractType = NFTContractTypeMapper().map(contractType: collection.contractType)

            return NFTCollection(
                collectionIdentifier: collectionIdentifier,
                chain: chain,
                contractType: contractType,
                ownerAddress: ownerAddress,
                name: name,
                description: nil, // Moralis doesn't provide descriptions for NFT collections
                logoURL: collection.collectionLogo?.nilIfEmpty.flatMap(URL.init(string:)),
                assetsCount: assetsCount,
                assets: [] // Moralis doesn't return the list of assets
            )
        }
    }

    /// - Note: `ownerAddress` is only used as a fallback value, so it is passed as `@autoclosure`.
    func map(assets: [MoralisNetworkResult.EVMNFTAsset], ownerAddress: @autoclosure () -> String) -> [NFTAsset] {
        return assets.compactMap { map(asset: $0, ownerAddress: ownerAddress()) }
    }

    /// - Note: `ownerAddress` is only used as a fallback value, so it is passed as `@autoclosure`.
    func map(asset: MoralisNetworkResult.EVMNFTAsset?, ownerAddress: @autoclosure () -> String) -> NFTAsset? {
        guard
            let asset,
            let assetIdentifier = asset.tokenId,
            let collectionIdentifier = asset.tokenAddress,
            let name = asset.name
        else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: token_id %@, token_address %@, name %@",
                    String(describing: asset?.tokenId),
                    String(describing: asset?.tokenAddress),
                    String(describing: asset?.name)
                )
            )
            return nil
        }

        let contractType = NFTContractTypeMapper().map(contractType: asset.contractType)
        let media = map(media: asset.media)
        let rarity = map(rarityLabel: asset.rarityLabel, rarityPercentage: asset.rarityPercentage, rarityRank: asset.rarityRank)
        let traits = map(attributes: asset.normalizedMetadata?.attributes)

        return NFTAsset(
            assetIdentifier: assetIdentifier,
            collectionIdentifier: collectionIdentifier,
            chain: chain,
            contractType: contractType,
            ownerAddress: asset.ownerOf ?? ownerAddress(),
            name: name,
            description: asset.normalizedMetadata?.description,
            media: media,
            rarity: rarity,
            traits: traits
        )
    }

    func map(prices: MoralisNetworkResult.EVMNFTPrices) -> NFTSalePrice? {
        guard
            let lastSalePrice = prices.lastSale?.price.flatMap(Decimal.init(stringValue:))
        else {
            NFTLogger.warning(
                String(
                    format: "Prices missing required fields: last_sale %@",
                    String(describing: prices.lastSale)
                )
            )
            return nil
        }

        let lowestSalePrice = prices.lowestSale?.price
            .flatMap(Decimal.init(stringValue:))
            .map(NFTSalePrice.Price.init(value:))

        let highestSalePrice = prices.highestSale?.price
            .flatMap(Decimal.init(stringValue:))
            .map(NFTSalePrice.Price.init(value:))

        return NFTSalePrice(
            last: NFTSalePrice.Price(value: lastSalePrice),
            lowest: lowestSalePrice,
            highest: highestSalePrice
        )
    }

    // MARK: - Private implementation

    private func map(media: MoralisNetworkResult.EVMNFTAsset.Media?) -> NFTAsset.Media? {
        guard
            let media,
            let url = media.originalMediaUrl?.nilIfEmpty.flatMap(URL.init(string:))
        else {
            NFTLogger.warning(
                String(
                    format: "Media missing required fields: mimetype %@, original_media_url %@",
                    String(describing: media?.mimetype),
                    String(describing: media?.originalMediaUrl)
                )
            )
            return nil
        }

        let mediaKind = NFTMediaKindMapper().map(mimetype: media.mimetype)

        return NFTAsset.Media(
            kind: mediaKind,
            url: url
        )
    }

    private func map(rarityLabel: String?, rarityPercentage: Double?, rarityRank: Double?) -> NFTAsset.Rarity? {
        guard let rarityLabel else {
            NFTLogger.warning(
                String(
                    format: "Rarity missing required fields: rarity_label %@",
                    String(describing: rarityLabel)
                )
            )
            return nil
        }

        let rank = rarityRank.map { Int($0) }

        return NFTAsset.Rarity(
            label: rarityLabel,
            percentage: rarityPercentage,
            rank: rank
        )
    }

    private func map(attributes: [MoralisNetworkResult.EVMNFTAsset.Attribute]?) -> [NFTAsset.Trait] {
        return attributes?.compactMap { attribute in
            guard
                let name = attribute.traitType,
                let value = attribute.value
            else {
                NFTLogger.warning(
                    String(
                        format: "Attribute missing required fields: trait_type %@, value %@",
                        String(describing: attribute.traitType),
                        String(describing: attribute.value)
                    )
                )
                return nil
            }

            return NFTAsset.Trait(name: name, value: value.description)
        } ?? []
    }
}
