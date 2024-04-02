//
//  CommonAnalyticsContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import class TangemExpress.ThreadSafeContainer

class CommonAnalyticsContext: AnalyticsContext {
    var contextData: AnalyticsContextData? {
        contextDataContainer.read()
    }

    private let contextDataContainer = ThreadSafeContainer<AnalyticsContextData?>(nil)
    private var analyticsStorage = AnalyticsStorage()

    init() {}

    func setupContext(with contextData: AnalyticsContextData) {
        contextDataContainer.mutate { $0 = contextData }
    }

    func clearContext() {
        contextDataContainer.mutate { $0 = nil }
    }

    func clearSession() {
        analyticsStorage.clearSessionStorage()
    }

    func value(forKey: AnalyticsStorageKey, scope: AnalyticsContextScope) -> Any? {
        guard let id = makeId(for: scope) else { return nil }

        return analyticsStorage.value(forKey, id: id)
    }

    func set(value: Any, forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope) {
        guard let id = makeId(for: scope) else { return }

        analyticsStorage.set(value, storageKey: storageKey, id: id)
    }

    func removeValue(forKey storageKey: AnalyticsStorageKey, scope: AnalyticsContextScope) {
        guard let id = makeId(for: scope) else { return }

        analyticsStorage.removeValue(storageKey, id: id)
    }

    private func makeId(for scope: AnalyticsContextScope) -> String? {
        switch scope {
        case .userWallet(let userWalletId):
            return userWalletId.stringValue
        case .common:
            return Constants.commonContextId
        }
    }
}

// MARK: - Constants

private extension CommonAnalyticsContext {
    enum Constants {
        static let commonContextId = "Common"
    }
}

// MARK: - AnalyticsStorage

private class AnalyticsStorage {
    private var tempStorage: [String: Any] = [:]

    func clearSessionStorage() {
        tempStorage = [:]
    }

    func value(_ storageKey: AnalyticsStorageKey, id: String) -> Any? {
        let rawKey = makeRawKey(from: storageKey, id: id)

        if storageKey.isPermanent {
            return UserDefaults.standard.value(forKey: rawKey)
        } else {
            return tempStorage[rawKey]
        }
    }

    func set(_ value: Any, storageKey: AnalyticsStorageKey, id: String) {
        let rawKey = makeRawKey(from: storageKey, id: id)

        if storageKey.isPermanent {
            UserDefaults.standard.set(value, forKey: rawKey)
        } else {
            tempStorage[rawKey] = value
        }
    }

    func removeValue(_ storageKey: AnalyticsStorageKey, id: String) {
        let rawKey = makeRawKey(from: storageKey, id: id)

        if storageKey.isPermanent {
            UserDefaults.standard.removeObject(forKey: rawKey)
        } else {
            tempStorage[rawKey] = nil
        }
    }

    private func makeRawKey(from key: AnalyticsStorageKey, id: String) -> String {
        return "\(id)_\(key.rawValue)"
    }
}
