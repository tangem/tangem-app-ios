//
//  CommonMarketingActivityBindingStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

actor CommonMarketingActivityBindingStore {
    private let persistentStorage: any PersistentStorageProtocol
    private var bindings: [MarketingActivityBinding] = []
    private var isLoaded = false
    private var hasUnsavedChanges = false

    init(persistentStorage: any PersistentStorageProtocol) {
        self.persistentStorage = persistentStorage
    }
}

// MARK: - MarketingActivityBindingStore

extension CommonMarketingActivityBindingStore: MarketingActivityBindingStore {
    @discardableResult
    func add(uid: String) -> MarketingActivityBinding {
        syncWithStorage()

        if let existing = bindings.first(where: { $0.uid == uid }) {
            return existing
        }

        let binding = MarketingActivityBinding(id: UUID(), uid: uid)
        commit(bindings + [binding])
        return binding
    }

    func pending() -> [MarketingActivityBinding] {
        syncWithStorage()

        return bindings
    }

    func remove(id: UUID) {
        syncWithStorage()

        commit(bindings.filter { $0.id != id })
    }
}

// MARK: - Private

private extension CommonMarketingActivityBindingStore {
    func syncWithStorage() {
        loadIfNeeded()

        if hasUnsavedChanges {
            save()
        }
    }

    func loadIfNeeded() {
        guard !isLoaded else {
            return
        }

        isLoaded = true

        do {
            bindings = try persistentStorage.value(for: .marketingActivityBindings) ?? []
        } catch {
            MarketingActivityLogger.error("Couldn't load pending marketing activity bindings, starting over", error: error)
        }
    }

    func commit(_ updated: [MarketingActivityBinding]) {
        guard updated != bindings else {
            return
        }

        bindings = updated
        save()
    }

    func save() {
        do {
            try persistentStorage.store(value: bindings, for: .marketingActivityBindings)
            hasUnsavedChanges = false
        } catch {
            hasUnsavedChanges = true
            MarketingActivityLogger.error("Couldn't save pending marketing activity bindings", error: error)
        }
    }
}
