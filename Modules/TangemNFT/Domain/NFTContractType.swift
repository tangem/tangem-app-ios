//
//  NFTContractType.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum NFTContractType: Hashable, Sendable, CustomStringConvertible {
    /// https://eips.ethereum.org/EIPS/eip-721
    case erc721
    /// https://eips.ethereum.org/EIPS/eip-1155
    case erc1155
    /// Other contract type, that was sent by a provider
    case other(String)
    /// Temporary solution while we need to parse some contract types
    /// and only send them to analytics without displaying them in the UI (e.g. for Solana)
    case analyticsOnly(String)
    /// Unknown contract type
    case unknown

    public var description: String {
        switch self {
        case .erc721:
            "erc721"
        case .erc1155:
            "erc1155"
        case .other(let string):
            string
        case .analyticsOnly(let string):
            string
        case .unknown:
            "unknown"
        }
    }
}

// MARK: - CaseIterable protocol conformance

extension NFTContractType: CaseIterable {
    /// Poor man's `CaseIterable`.
    public static var allCases: [NFTContractType] {
        switch NFTContractType.unknown {
        case .erc721:
            break
        case .erc1155:
            break
        case .unknown:
            break
        case .other:
            break
        case .analyticsOnly:
            break
        }
        // READ BELOW:
        //
        // Did you get a compilation error here? If so, add your new chain to the array below

        return [
            .erc721,
            .erc1155,
            .unknown,
            .other(""),
            .analyticsOnly(""),
        ]
    }
}
