//
//  BlockchainDataStorage.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol BlockchainDataStorage {
    // MARK: - Synchronous

    func get<BlockchainData>(key: String) -> BlockchainData? where BlockchainData: Decodable
    func store<BlockchainData>(key: String, value: BlockchainData?) where BlockchainData: Encodable

    // MARK: - Asynchronous

    /// - Note: Should be preferred over synchronous counterpart in cases when encoding/decoding is resource-intensive.
    func get<BlockchainData>(key: String) async -> BlockchainData? where BlockchainData: Decodable
    /// - Note: Should be preferred over synchronous counterpart in cases when encoding/decoding is resource-intensive.
    func store<BlockchainData>(key: String, value: BlockchainData?) async where BlockchainData: Encodable
}
