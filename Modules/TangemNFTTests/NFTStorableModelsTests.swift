//
//  NFTCachedModelsTests.swift
//  TangemNFTTests
//
//  Created on 25.05.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemNFT

@Suite("NFT Storable Models")
struct NFTCachedModelsTests {
    // MARK: - Tests

    @Test("Asset serialization and deserialization for all chains")
    func testAssetSerializationAndDeserialization() throws {
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
    func testAssetSerializationAndDeserializationWithEmptyOptionals() throws {
        // Create an asset with minimal data (all optionals set to nil)
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
            media: nil,
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
    func testAssetSerializationAndDeserializationWithRoundTrip() throws {
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
    func testAssetSerializationAndDeserializationWithContractTypes() throws {
        // Test all available contract types
        for contractType in NFTContractType.allCases {
            let originalAsset = createCompleteNFTAsset(
                chain: .ethereum(isTestnet: false),
                contractType: contractType,
                mediaKind: .image
            )

            let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)
            let restoredAsset = try storableModel.toNFTAsset()

            // Use direct equality comparison where possible
            #expect(restoredAsset == originalAsset, "Assets should be equal for contract type \(contractType)")
        }
    }

    @Test("Asset serialization and deserialization with media types")
    func testAssetSerializationAndDeserializationWithMediaTypes() throws {
        // Test all available media kinds
        for mediaKind in NFTMedia.Kind.allCases {
            let originalAsset = createCompleteNFTAsset(
                chain: .ethereum(isTestnet: false),
                contractType: .erc721,
                mediaKind: mediaKind
            )

            let storableModel = NFTCachedModels.V1.Asset(from: originalAsset)
            let restoredAsset = try storableModel.toNFTAsset()

            // Verify using full equality check
            #expect(
                restoredAsset == originalAsset,
                "Asset should be preserved for media type \(mediaKind)"
            )
        }
    }

    @Test("Asset codability (JSON encoding/decoding)")
    func testAssetCodability() throws {
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

        // Verify with direct asset comparison
        #expect(restoredAsset == originalAsset, "Asset should be equal after JSON encoding/decoding cycle")
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
        #expect(restoredAsset == originalAsset, "Restored asset should equal original for chain \(chain)")
    }

    private func createCompleteNFTAsset(
        chain: NFTChain,
        contractType: NFTContractType,
        mediaKind: NFTMedia.Kind
    ) -> NFTAsset {
        // Create a unique identifier based on chain and contract type
        let identifier = "nft_\(chain.id)_\(contractType)"

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

        let media = NFTMedia(
            kind: mediaKind,
            url: URL(string: "https://example.com/\(identifier).\(mediaExtension(for: mediaKind))")!
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
            media: media,
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
