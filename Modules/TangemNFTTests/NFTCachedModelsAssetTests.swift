//
//  NFTCachedModelsAssetTests.swift
//  TangemNFTTests
//
//  Created on 25.05.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemNFT

@Suite("NFTCachedModels.V1.Asset")
struct NFTCachedModelsAssetTests {
    // MARK: - Tests

    @Test("Asset serialization and deserialization for all chains")
    func assetSerializationAndDeserialization() throws {
        // Test serialization and deserialization for all possible chain types
        for chain in NFTChain.allCases(isTestnet: false) {
            try testAssetSerializationAndDeserialization(for: chain)
        }

        // Also test for testnet versions
        for chain in NFTChain.allCases(isTestnet: true) {
            try testAssetSerializationAndDeserialization(for: chain)
        }
    }

    @Test("Asset serialization and deserialization with empty optionals")
    func assetSerializationAndDeserializationWithEmptyOptionals() throws {
        // Create an asset domain model with minimal data (all optionals set to nil)
        let assetId = NFTAsset.NFTAssetId(
            identifier: "123",
            contractAddress: "0xabc",
            ownerAddress: "0xowner",
            chain: .ethereum(isTestnet: false),
            contractType: .erc721
        )

        let originalAsset = NFTAsset(
            assetIdentifier: assetId.identifier,
            assetContractAddress: assetId.contractAddress,
            chain: assetId.chain,
            contractType: assetId.contractType,
            decimalCount: 0,
            ownerAddress: assetId.ownerAddress,
            name: "Minimal NFT",
            description: nil,
            salePrice: nil,
            mediaFiles: [],
            rarity: nil,
            traits: []
        )

        // Test serialization and deserialization
        let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)
        let restoredAsset = try storableModel.toNFTAsset()

        // Verify that the restored asset matches the original using full equality
        #expect(restoredAsset == originalAsset, "Restored asset should be equal to original asset")
    }

    @Test("Asset serialization and deserialization with round trip")
    func assetSerializationAndDeserializationWithRoundTrip() throws {
        // Test that multiple serialization/deserialization cycles preserve data integrity
        let originalAsset = createCompleteNFTAsset(
            chain: .ethereum(isTestnet: false),
            contractType: .erc721,
            mediaKind: .image
        )

        // First round-trip
        let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)
        let restoredAsset = try storableModel.toNFTAsset()

        // Second round-trip
        let secondStorableModel = NFTCachedModels.V1.Asset(from: restoredAsset)
        let secondRestoredAsset = try secondStorableModel.toNFTAsset()

        // Verify that data remains consistent after multiple conversions
        #expect(secondRestoredAsset == originalAsset, "Asset should remain consistent after multiple serialization cycles")
    }

    @Test("Asset serialization and deserialization with contract types")
    func assetSerializationAndDeserializationWithContractTypes() throws {
        // Test all available contract types
        for contractType in NFTContractType.allCases {
            let originalAsset = createCompleteNFTAsset(
                chain: .ethereum(isTestnet: false),
                contractType: contractType,
                mediaKind: .image
            )

            let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)
            let restoredAsset = try storableModel.toNFTAsset()

            #expect(restoredAsset.id.contractType == originalAsset.id.contractType, "Assets should be equal for contract type '\(contractType)'")
        }
    }

    @Test("Asset serialization and deserialization with media types")
    func assetSerializationAndDeserializationWithMediaTypes() throws {
        // Test all available media kinds
        for mediaKind in NFTMedia.Kind.allCases {
            let originalAsset = createCompleteNFTAsset(
                chain: .ethereum(isTestnet: false),
                contractType: .erc721,
                mediaKind: mediaKind
            )

            let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)
            let restoredAsset = try storableModel.toNFTAsset()

            #expect(restoredAsset.mediaFiles == originalAsset.mediaFiles, "Assets should be equal for media kind '\(mediaKind)'")
        }
    }

    @Test("Asset codability (JSON encoding/decoding)")
    func assetCodability() throws {
        // Test that the storable model can be encoded to and decoded from JSON
        let originalAsset = createCompleteNFTAsset(
            chain: .ethereum(isTestnet: false),
            contractType: .erc721,
            mediaKind: .image
        )

        let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)

        // Encode to Data
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(storableModel)

        // Decode back to storable model
        let decoder = JSONDecoder()
        let decodedStorableModel = try decoder.decode(NFTCachedModels.V1.Asset.self, from: encodedData)

        // Convert back to NFT asset
        let restoredAsset = try decodedStorableModel.toNFTAsset()

        // Verify with full equality check
        #expect(restoredAsset == originalAsset, "Asset should be equal after JSON encoding/decoding cycle")
    }

    @Test("Asset serialization and deserialization with multiple media files")
    func assetSerializationAndDeserializationWithMultipleMediaFiles() throws {
        let mediaFiles = [
            NFTMedia(kind: .image, url: URL(string: "https://example.com/image1.png")!),
            NFTMedia(kind: .video, url: URL(string: "https://example.com/video1.mp4")!),
            NFTMedia(kind: .audio, url: URL(string: "https://example.com/audio1.mp3")!),
        ]

        let originalAsset = createCompleteNFTAsset(
            chain: .ethereum(isTestnet: false),
            contractType: .erc721,
            mediaFiles: mediaFiles
        )

        // Serialize and deserialize
        let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)
        let restoredAsset = try storableModel.toNFTAsset()

        // Assert that mediaFiles are preserved
        #expect(restoredAsset.mediaFiles == originalAsset.mediaFiles, "mediaFiles should be preserved after serialization/deserialization")
    }

    // MARK: - Private Helpers

    private func testAssetSerializationAndDeserialization(for chain: NFTChain) throws {
        // Create a complete asset with all fields populated
        let originalAsset = createCompleteNFTAsset(chain: chain, contractType: .erc721, mediaKind: .image)

        // Convert to storable model
        let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)

        // Convert back to NFT asset
        let restoredAsset = try storableModel.toNFTAsset()

        // Verify using full equality check
        #expect(restoredAsset == originalAsset, "Restored asset should equal original for chain '\(chain)'")
    }

    private func createCompleteNFTAsset(
        chain: NFTChain,
        contractType: NFTContractType,
        mediaKind: NFTMedia.Kind
    ) -> NFTAsset {
        // Create a unique identifier based on chain and contract type
        let identifier = "nft_\(chain.id)_\(contractType)"
        let media = NFTMedia(
            kind: mediaKind,
            url: URL(string: "https://example.com/\(identifier).\(mediaExtension(for: mediaKind))")!
        )

        return createCompleteNFTAsset(
            chain: chain,
            identifier: identifier,
            contractType: contractType,
            mediaFiles: [media]
        )
    }

    private func createCompleteNFTAsset(
        chain: NFTChain,
        contractType: NFTContractType,
        mediaFiles: [NFTMedia]
    ) -> NFTAsset {
        // Create a unique identifier based on chain and contract type
        let identifier = "nft_\(chain.id)_\(contractType)"

        return createCompleteNFTAsset(
            chain: chain,
            identifier: identifier,
            contractType: contractType,
            mediaFiles: mediaFiles
        )
    }

    private func createCompleteNFTAsset(
        chain: NFTChain,
        identifier: String,
        contractType: NFTContractType,
        mediaFiles: [NFTMedia]
    ) -> NFTAsset {
        // Create an NFT asset with all fields populated
        let assetId = NFTAsset.NFTAssetId(
            identifier: identifier,
            contractAddress: "0x\(identifier)_contract",
            ownerAddress: "0x\(identifier)_owner",
            chain: chain,
            contractType: contractType
        )

        let traits = [
            NFTAsset.Trait(name: "Background", value: "Blue"),
            NFTAsset.Trait(name: "Eyes", value: "Green"),
            NFTAsset.Trait(name: "Mouth", value: "Smile"),
        ]

        let salePrice = NFTSalePrice(
            last: NFTSalePrice.Price(value: 2.5),
            lowest: NFTSalePrice.Price(value: 1.0),
            highest: NFTSalePrice.Price(value: 5.0)
        )

        let rarity = NFTAsset.Rarity(
            label: "Rare",
            percentage: 12.5,
            rank: 42
        )

        return NFTAsset(
            assetIdentifier: assetId.identifier,
            assetContractAddress: assetId.contractAddress,
            chain: assetId.chain,
            contractType: assetId.contractType,
            decimalCount: 0,
            ownerAddress: assetId.ownerAddress,
            name: "Test \(identifier)",
            description: "This is a test NFT for \(chain.id)",
            salePrice: salePrice,
            mediaFiles: mediaFiles,
            rarity: rarity,
            traits: traits
        )
    }

    private func mediaExtension(for kind: NFTMedia.Kind) -> String {
        switch kind {
        case .image:
            return "png"
        case .animation:
            return "gif"
        case .video:
            return "mp4"
        case .audio:
            return "mp3"
        case .unknown:
            return "bin"
        }
    }
}
