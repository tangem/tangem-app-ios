//
//  ForceUpdateCache.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Persistent cache for the latest `ApplicationVersionsDTO` received from the backend.
/// The cache is read at app launch (before auth) and is updated after a successful refresh.
protocol ForceUpdateCache: AnyObject {
    var dto: ApplicationVersionsDTO? { get set }
}

final class UserDefaultsForceUpdateCache: ForceUpdateCache {
    @AppStorageCompat(StorageKeys.cachedDTO)
    private var storedData: Data? = nil

    var dto: ApplicationVersionsDTO? {
        get {
            guard let storedData else { return nil }
            return try? JSONDecoder().decode(ApplicationVersionsDTO.self, from: storedData)
        }
        set {
            storedData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
}

private extension UserDefaultsForceUpdateCache {
    enum StorageKeys: String, RawRepresentable {
        case cachedDTO = "force_update_cached_application_versions"
    }
}
