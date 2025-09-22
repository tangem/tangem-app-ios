//
//  CommonAnalyticsSessionContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine

class CommonAnalyticsSessionContext: AnalyticsSessionContext {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var analyticsStorage = AnalyticsStorage()
    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
    }

    func value(forKey: AnalyticsStorageKey, scope: AnalyticsSessionContextScope) -> Any? {
        guard let id = makeId(for: scope) else { return nil }

        return analyticsStorage.value(forKey, id: id)
    }

    func set(value: Any, forKey storageKey: AnalyticsStorageKey, scope: AnalyticsSessionContextScope) {
        guard let id = makeId(for: scope) else { return }

        analyticsStorage.set(value, storageKey: storageKey, id: id)
    }

    func removeValue(forKey storageKey: AnalyticsStorageKey, scope: AnalyticsSessionContextScope) {
        guard let id = makeId(for: scope) else { return }

        analyticsStorage.removeValue(storageKey, id: id)
    }

    private func makeId(for scope: AnalyticsSessionContextScope) -> String? {
        switch scope {
        case .userWallet(let userWalletId):
            return userWalletId.stringValue
        case .common:
            return Constants.commonContextId
        }
    }

    private func bind() {
        userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { context, event in
                switch event {
                case .locked:
                    context.analyticsStorage.clearSessionStorage()
                default:
                    break
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Constants

private extension CommonAnalyticsSessionContext {
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
