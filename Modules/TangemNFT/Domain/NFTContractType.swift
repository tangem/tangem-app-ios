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
        case .unknown:
            "unknown"
        }
    }
}
