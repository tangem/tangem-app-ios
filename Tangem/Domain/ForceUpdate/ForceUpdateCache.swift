//
//  ForceUpdateCache.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol ForceUpdateCache: AnyObject {
    var dto: ApplicationVersionsDTO? { get set }
}

final class DefaultForceUpdateCache: ForceUpdateCache {
    // [REDACTED_TODO_COMMENT]
    private let storage: BlockchainDataStorage
    private let ttl: TimeInterval
    private let now: () -> Date
    private let key = "force_update_application_versions"

    init(
        storage: BlockchainDataStorage,
        ttl: TimeInterval,
        now: @escaping () -> Date
    ) {
        self.storage = storage
        self.ttl = ttl
        self.now = now
    }

    var dto: ApplicationVersionsDTO? {
        get {
            guard let entry: Entry = storage.get(key: key) else {
                return nil
            }
            guard now().timeIntervalSince(entry.storedAt) < ttl else {
                return nil
            }
            return entry.dto
        }
        set {
            let entry = newValue.map { Entry(dto: $0, storedAt: now()) }
            storage.store(key: key, value: entry)
        }
    }
}

private extension DefaultForceUpdateCache {
    struct Entry: Codable {
        let dto: ApplicationVersionsDTO
        let storedAt: Date
    }
}
