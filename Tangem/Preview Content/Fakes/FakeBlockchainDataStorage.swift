//
//  FakeBlockchainDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

final class FakeBlockchainDataStorage {
    private var storage: [String: Any] = [:]
}

// MARK: - BlockchainDataStorage protocol conformance

extension FakeBlockchainDataStorage: BlockchainDataStorage {
    func get<BlockchainData>(key: String) -> BlockchainData? where BlockchainData: Decodable {
        return storage[key] as? BlockchainData
    }

    func get<BlockchainData>(key: String) async -> BlockchainData? where BlockchainData: Decodable {
        return await Task {
            get(key: key)
        }.value
    }

    func store<BlockchainData>(key: String, value: BlockchainData?) where BlockchainData: Encodable {
        storage[key] = value
    }

    func store<BlockchainData>(key: String, value: BlockchainData?) async where BlockchainData: Encodable {
        Task {
            store(key: key, value: value)
        }
    }
}
