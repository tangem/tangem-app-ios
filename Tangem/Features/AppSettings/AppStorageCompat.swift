//
//  AppStorageCompat.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemFoundation

/// Drop with IOS 14 minimum deployment target
/// A property wrapper type that reflects a value from `UserDefaults` and
/// invalidates a view on a change in value in that user default.
@frozen @propertyWrapper
public struct AppStorageCompat<Key: RawRepresentable<String>, Value>: DynamicProperty {
    @ObservedObject private var _value: Storage<Value>
    private let saveValue: (Value) -> Void

    private init(
        value: Value,
        store: UserDefaults,
        key: Key,
        transform: @escaping (Any?) -> Value?,
        saveValue: @escaping (Value) -> Void
    ) {
        _value = Storage(value: value, store: store, key: key.rawValue, transform: transform)
        self.saveValue = saveValue
    }

    public var wrappedValue: Value {
        get {
            _value.value
        }
        set {
            saveValue(newValue)
        }
    }

    public var projectedValue: Published<Value>.Publisher {
        _value.$publishedValue
    }
}

@usableFromInline
final class Storage<Value>: NSObject, ObservableObject {
    @Published var publishedValue: Value

    var value: Value {
        store.value(forKey: keyPath).flatMap(transform) ?? defaultValue
    }

    private let defaultValue: Value
    private let store: UserDefaults
    private let keyPath: String
    private let transform: (Any?) -> Value?

    init(value: Value, store: UserDefaults, key: String, transform: @escaping (Any?) -> Value?) {
        publishedValue = value
        defaultValue = value
        self.store = store
        keyPath = key
        self.transform = transform
        super.init()

        store.addObserver(self, forKeyPath: key, options: [.new], context: nil)
    }

    deinit {
        store.removeObserver(self, forKeyPath: keyPath)
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        DispatchQueue.main.async {
            self.publishedValue = change?[.newKey].flatMap(self.transform) ?? self.defaultValue
        }
    }
}

extension AppStorageCompat where Value: PropertyListObjectRepresentable {
    /// Creates a property that can read and write to a user default value of type
    /// that conforms `PropertyListObjectRepresentable`.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if value is not specified for the given key.
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    init(wrappedValue: Value, _ key: Key, store: UserDefaults? = .defaultStore) {
        let store = (store ?? .standard)
        let initialValue = store.value(forKey: key.rawValue) as? Value ?? wrappedValue
        self.init(value: initialValue, store: store, key: key, transform: {
            $0 as? Value
        }, saveValue: { newValue in
            store.setValue(newValue, forKey: key.rawValue)
        })
    }
}

extension AppStorageCompat where Value: PropertyListObjectRepresentable, Value: OptionalProtocol {
    /// Creates a property that can read and write to a user default value of
    /// the optional type that conforms `PropertyListObjectRepresentable`.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if value is not specified for the given key.
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    init(wrappedValue: Value, _ key: Key, store: UserDefaults? = .defaultStore) {
        let store = (store ?? .standard)
        let initialValue = store.value(forKey: key.rawValue) as? Value ?? wrappedValue
        self.init(value: initialValue, store: store, key: key, transform: {
            $0 as? Value
        }, saveValue: { newValue in
            switch newValue.wrapped {
            case .none:
                store.removeObject(forKey: key.rawValue)
            case .some:
                store.setValue(newValue, forKey: key.rawValue)
            }
        })
    }
}

extension AppStorageCompat where Value: RawRepresentable, Value.RawValue: PropertyListObjectRepresentable {
    /// Creates a property that can read and write to an integer user default,
    /// transforming that to `RawRepresentable` data type.
    ///
    /// A common usage is with enumerations:
    ///
    ///     enum MyEnum: Int {
    ///         case a
    ///         case b
    ///         case c
    ///     }
    ///     struct MyView: View {
    ///         [REDACTED_USERNAME]("MyEnumValue") private var value = MyEnum.a
    ///         var body: some View { ... }
    ///     }
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if an integer value
    ///     is not specified for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    init(wrappedValue: Value, _ key: Key, store: UserDefaults? = .defaultStore) {
        let store = (store ?? .standard)
        let rawValue = store.value(forKey: key.rawValue) as? Value.RawValue
        let initialValue = rawValue.flatMap(Value.init) ?? wrappedValue
        self.init(value: initialValue, store: store, key: key, transform: {
            ($0 as? Value.RawValue).flatMap(Value.init)
        }, saveValue: { newValue in
            store.setValue(newValue.rawValue, forKey: key.rawValue)
        })
    }
}

extension AppStorageCompat where Value == [Feature: FeatureState] {
    /// Creates a property that can read and write to an integer user default.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if an integer value is not specified
    ///     for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    init(wrappedValue: Value, _ key: Key, store: UserDefaults? = .defaultStore) {
        let store = (store ?? .standard)
        let initialValue = store.value(forKey: key.rawValue) as? Value ?? wrappedValue
        self.init(value: initialValue, store: store, key: key) { value in
            let dictionary = (value as? [String: String]) ?? [:]

            return dictionary.reduce(into: [:]) { result, element in
                if let toggle = Feature(rawValue: element.key),
                   let state = FeatureState(rawValue: element.value) {
                    result[toggle] = state
                }
            }
        } saveValue: { newValue in
            let dictionary = newValue.reduce(into: [:]) { result, element in
                result[element.key.rawValue] = element.value.rawValue
            }
            store.setValue(dictionary, forKey: key.rawValue)
        }
    }
}

// MARK: - Convenience extensions

private extension UserDefaults {
    static var defaultStore: Self? { Self(suiteName: AppEnvironment.current.suiteName) }
}
