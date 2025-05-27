//
//  NFTCachedModels.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Namespace for storing all types related to persistable NFT models
public enum NFTCachedModels {
    /// Versioning namespace
    public enum V1 {}

    /// Error types
    enum Error: Swift.Error {
        case decodingError(String)
    }
}
