//
//  MoralisNetworkMapper.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

struct MoralisEVMNetworkMapper {
    let chain: NFTChain

    func map(collections: [MoralisEVMNetworkResult.EVMNFTCollection], ownerAddress: String) -> [NFTCollection] {
        return collections.compactMap { collection in
            guard
                let collectionIdentifier = collection.tokenAddress,
                let assetsCount = collection.count
            else {
                NFTLogger.warning(
                    String(
                        format: "Collection missing required fields: token_address %@, count %@",
                        String(describing: collection.tokenAddress),
                        String(describing: collection.count)
                    )
                )
                return nil
            }

            let contractType = NFTContractTypeMapper.map(contractType: collection.contractType)

            return NFTCollection(
                collectionIdentifier: collectionIdentifier,
                chain: chain,
                contractType: contractType,
                ownerAddress: ownerAddress,
                name: collection.name?.nilIfEmpty ?? Constants.collectionNameFallback,
                description: nil, // Moralis doesn't provide descriptions for NFT collections
                media: map(collection.collectionLogo),
                assetsCount: assetsCount,
                assetsResult: [] // Moralis doesn't send assets
            )
        }
    }

    /// - Note: `ownerAddress and fallbackDescription` are only used as a fallback values, so they are passed as `@autoclosure`.
    func map(
        assets: [MoralisEVMNetworkResult.EVMNFTAsset],
        ownerAddress: @autoclosure () -> String,
        fallbackDescription: @autoclosure () -> String?
    ) -> [NFTAsset] {
        return assets.compactMap {
            map(
                asset: $0,
                ownerAddress: ownerAddress(),
                fallbackDescription: fallbackDescription()
            )
        }
    }

    /// - Note: `ownerAddress and fallbackDescription` are only used as a fallback values, so it is passed as `@autoclosure`.
    func map(
        asset: MoralisEVMNetworkResult.EVMNFTAsset?,
        ownerAddress: @autoclosure () -> String,
        fallbackDescription: @autoclosure () -> String?
    ) -> NFTAsset? {
        guard
            let asset,
            let assetIdentifier = asset.tokenId,
            let assetContractAddress = asset.tokenAddress
        else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: token_id %@, token_address %@",
                    String(describing: asset?.tokenId),
                    String(describing: asset?.tokenAddress)
                )
            )
            return nil
        }

        // [REDACTED_TODO_COMMENT]
        let mediaFiles = map(media: asset.media).map { [$0] } ?? []
        let contractType = NFTContractTypeMapper.map(contractType: asset.contractType)
        let rarity = map(rarityLabel: asset.rarityLabel, rarityPercentage: asset.rarityPercentage, rarityRank: asset.rarityRank)
        let traits = map(attributes: asset.normalizedMetadata?.attributes)

        return NFTAsset(
            assetIdentifier: assetIdentifier,
            assetContractAddress: assetContractAddress,
            chain: chain,
            contractType: contractType,
            decimalCount: Constants.decimalCount,
            ownerAddress: asset.ownerOf ?? ownerAddress(),
            name: asset.name?.nilIfEmpty ?? asset.normalizedMetadata?.name?.nilIfEmpty ?? Constants.assetNameFallback,
            description: asset.normalizedMetadata?.description?.nilIfEmpty ?? fallbackDescription(),
            salePrice: nil,
            mediaFiles: mediaFiles,
            rarity: rarity,
            traits: traits
        )
    }

    func map(prices: MoralisEVMNetworkResult.EVMNFTPrices) -> NFTSalePrice? {
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

    private func map(media: MoralisEVMNetworkResult.EVMNFTAsset.Media?) -> NFTMedia? {
        guard let media else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: media %@",
                    String(describing: media)
                )
            )
            return nil
        }

        var mediaURL: URL?
        let collection = media.mediaCollection

        let mediaURLs = [
            collection?.high?.url,
            collection?.medium?.url,
            collection?.low?.url,
            media.originalMediaUrl,
        ]

        for urlString in mediaURLs {
            if let url = urlString?
                .nilIfEmpty
                .flatMap(URL.init(string:))
                .map(NFTIPFSURLConverter.convert(_:)) {
                mediaURL = url
                break
            }
        }

        guard let mediaURL else {
            NFTLogger.warning(
                String(
                    format: "Media missing required fields: high.url %@, medium.url %@, low.url %@, original_media_url %@",
                    String(describing: collection?.high?.url),
                    String(describing: collection?.medium?.url),
                    String(describing: collection?.low?.url),
                    String(describing: media.originalMediaUrl)
                )
            )
            return nil
        }

        return NFTMedia(
            kind: NFTMediaKindMapper.map(mimetype: media.mimetype, defaultKind: .image),
            url: mediaURL
        )
    }

    private func map(_ urlString: String?) -> NFTMedia? {
        guard
            let rawURL = urlString?
            .nilIfEmpty
            .flatMap(URL.init(string:))
        else {
            return nil
        }

        let kind = NFTMediaKindMapper.map(rawURL, defaultKind: .image)
        let url = NFTIPFSURLConverter.convert(rawURL)

        return NFTMedia(kind: kind, url: url)
    }

    private func map(rarityLabel: String?, rarityPercentage: Double?, rarityRank: Double?) -> NFTAsset.Rarity? {
        guard rarityLabel != nil || rarityPercentage != nil || rarityRank != nil else {
            return nil
        }

        return NFTAsset.Rarity(
            label: rarityLabel,
            percentage: rarityPercentage,
            rank: rarityRank.map { Int($0) }
        )
    }

    private func map(attributes: [MoralisEVMNetworkResult.EVMNFTAsset.Attribute]?) -> [NFTAsset.Trait] {
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

private extension MoralisEVMNetworkMapper {
    enum Constants {
        /// Moralis doesn't provide decimal count for EVM NFT collections,
        /// so we're using this default value instead.
        static let decimalCount = 0
        static var collectionNameFallback: String { Localization.nftUntitledCollection }
        static var assetNameFallback: String { .enDashSign }
    }
}
