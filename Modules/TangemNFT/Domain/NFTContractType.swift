//
//  NFTContractType.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum NFTContractType: Hashable, Sendable {
    /// https://eips.ethereum.org/EIPS/eip-721
    case erc721
    /// https://eips.ethereum.org/EIPS/eip-1155
    case erc1155
    /// https://spl.solana.com/token
    case splToken
    /// https://spl.solana.com/token-2022
    case splToken2022
    /// https://tonresear.ch/t/tep-62-establishing-a-unified-nft-standard-in-the-ton-ecosystem
    case tep62
    /// Unknown NFT type
    case unknown
}
