//
//  MoralisSolanaNetworkMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

struct MoralisSolanaNetworkMapper {
    func map(
        collection: MoralisSolanaNetworkResult.Collection?,
        assets: [MoralisSolanaNetworkResult.Asset],
        ownerAddress: String
    ) -> NFTCollection {
        let domainAssets = assets.compactMap {
            map(
                asset: $0,
                ownerAddress: ownerAddress,
                // We should use collection description as an asset's description
                // when asset's description is missing. (In case of Moralis for Solana -- always)
                description: collection?.description
            )
        }

        // Moralis doesn't send collection image URL, so we are assigning first asset's image or animation
        let collectionMedia = domainAssets
            .compactMap { NFTAssetMediaExtractor.extractMedia(from: $0) }
            .first

        guard let collection, let collectionId = collection.collectionAddress else {
            return NFTDummyCollectionMapper.map(
                chain: .solana,
                assets: domainAssets,
                assetsCount: domainAssets.count,
                contractType: .unknown,
                ownerAddress: ownerAddress,
                description: collection?.description,
                media: collectionMedia
            )
        }

        return NFTCollection(
            collectionIdentifier: collectionId,
            chain: .solana,
            contractType: .unknown,
            ownerAddress: ownerAddress,
            name: collection.name?.nilIfEmpty ?? Constants.collectionNameFallback,
            description: collection.description,
            media: collectionMedia,
            assetsCount: domainAssets.count,
            assetsResult: NFTPartialResult(value: domainAssets)
        )
    }

    private func map(
        asset: MoralisSolanaNetworkResult.Asset,
        ownerAddress: String,
        description: String?
    ) -> NFTAsset? {
        // `mint` field is the actual contract address for Solana NFTs
        guard let contractAddress = asset.mint else {
            NFTLogger.warning(
                String(
                    format: "Asset missing required fields: mint %@",
                    String(describing: asset.mint)
                )
            )
            return nil
        }

        let rarity = mapToRarity(attributes: asset.attributes)
        let mediaFiles = mapToMediaFiles(properties: asset.properties)
        let traits = mapToTraits(attributes: asset.attributes)
        let decimalCount = asset.decimals ?? Constants.decimalCountFallback
        let standard = NFTContractTypeMapper.map(
            contractType: asset.tokenStandard.flatMap(String.init),
            isAnalyticsOnly: true
        )

        return NFTAsset(
            assetIdentifier: Constants.dummyAssetIdentifier,
            assetContractAddress: contractAddress,
            chain: .solana,
            contractType: standard,
            decimalCount: decimalCount,
            ownerAddress: ownerAddress,
            name: asset.name?.nilIfEmpty ?? Constants.assetNameFallback,
            description: description,
            salePrice: nil,
            mediaFiles: mediaFiles,
            rarity: rarity,
            traits: traits
        )
    }

    private func mapToRarity(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> NFTAsset.Rarity? {
        guard let rarityAttribute = attributes?.first(where: { $0.traitType == Constants.rarityRankTitle }) else {
            return nil
        }

        guard let rank = rarityAttribute.value?.value as? Int else {
            NFTLogger.warning(
                String(
                    format: "Rarity missing required fields: value %@",
                    String(describing: rarityAttribute.value)
                )
            )
            return nil
        }

        return NFTAsset.Rarity(
            label: nil,
            percentage: nil,
            rank: rank
        )
    }

    private func mapToMediaFiles(properties: MoralisSolanaNetworkResult.Properties?) -> [NFTMedia] {
        return properties?
            .files?
            .compactMap { file -> NFTMedia? in
                guard
                    let uri = file.uri?.nilIfEmpty,
                    let rawURL = URL(string: uri)
                else {
                    NFTLogger.warning(
                        String(
                            format: "Media missing required fields: uri %@",
                            String(describing: file.uri)
                        )
                    )
                    return nil
                }

                let kind = NFTMediaKindMapper.map(mimetype: file.type, defaultKind: .image)
                let url = NFTIPFSURLConverter.convert(rawURL)

                return NFTMedia(kind: kind, url: url)
            } ?? []
    }

    private func mapToTraits(attributes: [MoralisSolanaNetworkResult.Attribute]?) -> [NFTAsset.Trait] {
        attributes?.compactMap { attribute in
            guard attribute.traitType != Constants.rarityRankTitle else {
                return nil
            }

            guard
                let name = attribute.traitType,
                let value = attribute.value?.value as? String
            else {
                NFTLogger.warning(
                    String(
                        format: "Attribute missing required fields: traitType %@, value %@",
                        String(describing: attribute.traitType),
                        String(describing: attribute.value)
                    )
                )
                return nil
            }

            return NFTAsset.Trait(name: name, value: value)
        } ?? []
    }
}

private extension MoralisSolanaNetworkMapper {
    enum Constants {
        /// Solana NFTs don't have a unique Token ID in the form of a UInt256 number like EVM NFTs do,
        /// so we're using this default value instead.
        static let dummyAssetIdentifier = ""
        /// Moralis provides descriptions for Solana NFT collections, so this value is used only as a fallback.
        static let decimalCountFallback = 0
        static let rarityRankTitle = "Rarity Rank"
        static var collectionNameFallback: String { Localization.nftUntitledCollection }
        static var assetNameFallback: String { .enDashSign }
    }
}
