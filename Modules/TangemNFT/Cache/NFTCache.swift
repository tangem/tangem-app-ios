//
//  NFTCache.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public class NFTCache {
    private let storage: CachesDirectoryStorage

    public init(
        cacheFileName: CachesDirectoryStorage.File
    ) {
        storage = CachesDirectoryStorage(file: cacheFileName)
    }

    public func getCollections() -> [NFTCollection] {
        do {
            let value: [NFTStorableModels.V1.NFTCollectionPOSS] = try storage.value()
            return try value.map { try $0.toNFTCollection() }
        } catch {
            NFTLogger.error("Failed to load cached collections", error: error)
            return []
        }
    }

    public func save(_ collections: [NFTCollection]) {
        let storableCollections = collections.map { NFTStorableModels.V1.NFTCollectionPOSS(from: $0) }
        storage.store(value: storableCollections)
    }

    public func delete(_ collections: [NFTCollection]) {
        // [REDACTED_TODO_COMMENT]
    }
}
