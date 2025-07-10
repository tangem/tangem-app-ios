//
//  BlockchainDataStorage.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol BlockchainDataStorage {
    func get<BlockchainData>(key: String) async -> BlockchainData? where BlockchainData: Decodable
    func store<BlockchainData>(key: String, value: BlockchainData?) async where BlockchainData: Encodable
}
