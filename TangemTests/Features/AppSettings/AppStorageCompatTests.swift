//
//  AppStorageCompatTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import Tangem

@MainActor
@Suite("AppStorageCompat")
struct AppStorageCompatTests {
    @Test("Reads the value persisted before the wrapper was created")
    func readsPersistedValue() {
        let store = makeStore()
        store.set(Constants.persistedValue, forKey: TestKey.optionalString.rawValue)

        let storage = AppStorageCompat<TestKey, String?>(wrappedValue: nil, .optionalString, store: store)

        #expect(storage.wrappedValue == Constants.persistedValue)
    }

    @Test("Setting an optional value to nil returns nil, not the value persisted at launch")
    func settingNilReturnsNil() {
        let store = makeStore()
        store.set(Constants.persistedValue, forKey: TestKey.optionalString.rawValue)
        var storage = AppStorageCompat<TestKey, String?>(wrappedValue: nil, .optionalString, store: store)

        storage.wrappedValue = nil

        #expect(store.object(forKey: TestKey.optionalString.rawValue) == nil)
        #expect(storage.wrappedValue == nil)
    }

    @Test("Setting an optional value to nil publishes nil", .timeLimit(.minutes(1)))
    func settingNilPublishesNil() async {
        let store = makeStore()
        store.set(Constants.persistedValue, forKey: TestKey.optionalString.rawValue)
        var storage = AppStorageCompat<TestKey, String?>(wrappedValue: nil, .optionalString, store: store)
        var cancellable: AnyCancellable?

        let published: String? = await withCheckedContinuation { continuation in
            cancellable = storage.projectedValue
                .dropFirst()
                .first()
                .sink { continuation.resume(returning: $0) }

            storage.wrappedValue = nil
        }
        cancellable?.cancel()

        #expect(published == nil)
    }

    @Test("A non-optional value removed from the store falls back to the declared default")
    func removedNonOptionalValueReturnsDeclaredDefault() {
        let store = makeStore()
        store.set(Constants.persistedFlag, forKey: TestKey.flag.rawValue)
        let storage = AppStorageCompat<TestKey, Bool>(wrappedValue: Constants.defaultFlag, .flag, store: store)

        store.removeObject(forKey: TestKey.flag.rawValue)

        #expect(storage.wrappedValue == Constants.defaultFlag)
    }

    @Test("Setting an optional value with a non-nil default to nil returns nil")
    func settingNilIgnoresNonNilDefault() {
        let store = makeStore()
        var storage = AppStorageCompat<TestKey, Int?>(wrappedValue: Constants.defaultNumber, .optionalNumber, store: store)

        storage.wrappedValue = Constants.assignedNumber
        storage.wrappedValue = nil

        #expect(storage.wrappedValue == nil)
    }

    @Test("Setting nil over a value persisted at launch returns nil even with a non-nil default")
    func settingNilOverPersistedValueIgnoresNonNilDefault() {
        let store = makeStore()
        store.set(Constants.persistedNumber, forKey: TestKey.optionalNumber.rawValue)
        var storage = AppStorageCompat<TestKey, Int?>(wrappedValue: Constants.defaultNumber, .optionalNumber, store: store)

        storage.wrappedValue = nil

        #expect(storage.wrappedValue == nil)
    }

    @Test("An optional value set to nil stays nil for a wrapper created afterwards")
    func nilSurvivesNewWrapper() {
        let store = makeStore()
        var storage = AppStorageCompat<TestKey, Int?>(wrappedValue: Constants.defaultNumber, .optionalNumber, store: store)
        storage.wrappedValue = Constants.assignedNumber
        storage.wrappedValue = nil

        let recreated = AppStorageCompat<TestKey, Int?>(wrappedValue: Constants.defaultNumber, .optionalNumber, store: store)

        #expect(recreated.wrappedValue == nil)
    }

    @Test("An optional value removed from the store outside the wrapper returns nil")
    func removedOptionalValueReturnsNil() {
        let store = makeStore()
        store.set(Constants.persistedValue, forKey: TestKey.optionalString.rawValue)
        let storage = AppStorageCompat<TestKey, String?>(wrappedValue: nil, .optionalString, store: store)

        store.removeObject(forKey: TestKey.optionalString.rawValue)

        #expect(storage.wrappedValue == nil)
    }

    @Test("A non-optional value reads the declared default when nothing is persisted")
    func nonOptionalReadsDeclaredDefault() {
        let store = makeStore()

        let storage = AppStorageCompat<TestKey, Bool>(wrappedValue: Constants.defaultFlag, .flag, store: store)

        #expect(storage.wrappedValue == Constants.defaultFlag)
    }

    @Test("A non-optional value removed from the store publishes the declared default", .timeLimit(.minutes(1)))
    func removedNonOptionalValuePublishesDeclaredDefault() async {
        let store = makeStore()
        store.set(Constants.persistedFlag, forKey: TestKey.flag.rawValue)
        let storage = AppStorageCompat<TestKey, Bool>(wrappedValue: Constants.defaultFlag, .flag, store: store)
        var cancellable: AnyCancellable?

        let published: Bool = await withCheckedContinuation { continuation in
            cancellable = storage.projectedValue
                .dropFirst()
                .first()
                .sink { continuation.resume(returning: $0) }

            store.removeObject(forKey: TestKey.flag.rawValue)
        }
        cancellable?.cancel()

        #expect(published == Constants.defaultFlag)
    }
}

private extension AppStorageCompatTests {
    enum TestKey: String {
        case optionalString
        case optionalNumber
        case flag
    }

    enum Constants {
        static let persistedValue = "persisted"
        static let persistedFlag = true
        static let defaultFlag = false
        static let defaultNumber = 1
        static let assignedNumber = 2
        static let persistedNumber = 5
    }

    func makeStore() -> UserDefaults {
        let suiteName = "AppStorageCompatTests.\(UUID().uuidString)"
        let store = UserDefaults(suiteName: suiteName)!
        store.removePersistentDomain(forName: suiteName)
        return store
    }
}
