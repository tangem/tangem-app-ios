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

    public weak var delegate: NFTCacheDelegate?

    public init(
        cacheFileName: CachesDirectoryStorage.File
    ) {
        storage = CachesDirectoryStorage(file: cacheFileName)
    }

    public func getCollections() -> [NFTCollection] {
        do {
            let storedCollections: [NFTCachedModels.V1.Collection] = try storage.value()
            let collections = try storedCollections.map { try $0.toNFTCollection() }

            return filteredCollections(from: collections)
        } catch {
            // All errors are intentionally ignored, since the cache is not critical for the app's functionality
            NFTLogger.error("Failed to load cached collections", error: error)

            return []
        }
    }

    public func save(_ collections: [NFTCollection]) {
        let storableCollections = collections.map { NFTCachedModels.V1.Collection(from: $0) }
        storage.store(value: storableCollections) { error in
            guard let error else {
                return
            }

            // All errors are intentionally ignored, since the cache is not critical for the app's functionality
            NFTLogger.error("Failed to save cached collections", error: error)
        }
    }

    public func clear() {
        save([])
    }

    private func filteredCollections(from collections: [NFTCollection]) -> [NFTCollection] {
        guard let delegate else {
            return collections
        }

        return collections.filter { delegate.cache(self, shouldRetrieveCollection: $0) }
    }
}
