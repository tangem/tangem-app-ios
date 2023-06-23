//
//  StorageEntryAdding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk

protocol StorageEntryAdding {
    var derivationStyle: DerivationStyle? { get }

    func getBlockchainNetwork(for blockchain: Blockchain, derivationPath: DerivationPath?) -> BlockchainNetwork
    func add(entry: StorageEntry) async throws -> String
}
