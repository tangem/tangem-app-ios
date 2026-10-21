//
//  CollectiblesSecureStorage.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import TangemSdk

public protocol CollectiblesSecureStorage {
    func get(_ account: String) throws -> Data?
    func store(_ object: Data, forKey account: String, overwrite: Bool) throws
    func delete(_ account: String) throws
}

extension SecureStorage: CollectiblesSecureStorage {}
