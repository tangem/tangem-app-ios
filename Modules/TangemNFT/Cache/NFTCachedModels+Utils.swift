//
//  NFTCachedModelsUtils.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Shared Chain Serialization/Deserialization

extension NFTCachedModels {
    /// Helper utilities for serializing and deserializing NFT chain information
    enum ChainUtils {
        /// Convert NFTChain to string representation and isTestnet flag
        static func serialize(_ chain: NFTChain) -> (chainName: String, isTestnet: Bool) {
            switch chain {
            case .ethereum(let isTestnet):
                return ("ethereum", isTestnet)
            case .polygon(let isTestnet):
                return ("polygon", isTestnet)
            case .bsc(let isTestnet):
                return ("bsc", isTestnet)
            case .avalanche:
                return ("avalanche", false)
            case .fantom(let isTestnet):
                return ("fantom", isTestnet)
            case .cronos:
                return ("cronos", false)
            case .arbitrum(let isTestnet):
                return ("arbitrum", isTestnet)
            case .chiliz(let isTestnet):
                return ("chiliz", isTestnet)
            case .base(let isTestnet):
                return ("base", isTestnet)
            case .optimism(let isTestnet):
                return ("optimism", isTestnet)
            case .moonbeam(let isTestnet):
                return ("moonbeam", isTestnet)
            case .moonriver(let isTestnet):
                return ("moonriver", isTestnet)
            case .solana:
                return ("solana", false)
            }
        }

        /// Deserialize chain from string representation and testnet flag
        static func deserialize(chainName: String, isTestnet: Bool) throws -> NFTChain {
            switch chainName {
            case "ethereum":
                return .ethereum(isTestnet: isTestnet)
            case "polygon":
                return .polygon(isTestnet: isTestnet)
            case "bsc":
                return .bsc(isTestnet: isTestnet)
            case "avalanche":
                return .avalanche
            case "fantom":
                return .fantom(isTestnet: isTestnet)
            case "cronos":
                return .cronos
            case "arbitrum":
                return .arbitrum(isTestnet: isTestnet)
            case "chiliz":
                return .chiliz(isTestnet: isTestnet)
            case "base":
                return .base(isTestnet: isTestnet)
            case "optimism":
                return .optimism(isTestnet: isTestnet)
            case "moonbeam":
                return .moonbeam(isTestnet: isTestnet)
            case "moonriver":
                return .moonriver(isTestnet: isTestnet)
            case "solana":
                return .solana
            default:
                throw NFTCachedModels.Error.decodingError("Unknown chain name: \(chainName)")
            }
        }
    }
}

// MARK: - Shared Contract Type Serialization/Deserialization

extension NFTCachedModels {
    /// Prefix that is used to identify anlytics-only contract types
    static let analyticOnlyPrefix = "analytic-only-"

    /// Helper utilities for serializing and deserializing NFT contract types
    enum ContractTypeUtils {
        /// Convert NFTContractType to string representation
        static func serialize(_ contractType: NFTContractType) -> String {
            switch contractType {
            case .erc721:
                return "erc721"
            case .erc1155:
                return "erc1155"
            case .unknown:
                return "unknown"
            case .other(let value):
                return value
            case .analyticsOnly(let value):
                return analyticOnlyPrefix + value
            }
        }

        /// Deserialize contract type from string representation
        static func deserialize(contractTypeIdentifier: String) -> NFTContractType {
            switch contractTypeIdentifier {
            case "erc721":
                return .erc721
            case "erc1155":
                return .erc1155
            case "unknown":
                return .unknown
            default:
                if contractTypeIdentifier.starts(with: analyticOnlyPrefix) {
                    let value = String(contractTypeIdentifier.dropFirst(analyticOnlyPrefix.count))
                    return .analyticsOnly(value)
                }

                return .other(contractTypeIdentifier)
            }
        }
    }
}

// MARK: - Shared Media Serialization/Deserialization

extension NFTCachedModels {
    /// Helper utilities for serializing and deserializing NFT media information
    enum MediaUtils {
        /// Convert NFTMedia.Kind to string representation
        static func serialize(_ mediaKind: NFTMedia.Kind) -> String {
            switch mediaKind {
            case .image:
                return "image"
            case .animation:
                return "animation"
            case .video:
                return "video"
            case .audio:
                return "audio"
            case .unknown:
                return "unknown"
            }
        }

        /// Deserialize media kind from string representation
        static func deserialize(mediaKindName: String) -> NFTMedia.Kind {
            switch mediaKindName {
            case "image":
                return .image
            case "animation":
                return .animation
            case "video":
                return .video
            case "audio":
                return .audio
            default:
                return .unknown
            }
        }

        /// Create NFTMedia from URL and kind name
        static func createMedia(url: URL, kindName: String) -> NFTMedia {
            let kind = deserialize(mediaKindName: kindName)

            return NFTMedia(kind: kind, url: url)
        }
    }
}
