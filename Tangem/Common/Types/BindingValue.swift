//
//  BindingValue.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BindingValue<Value> {
    private let get: () -> Value
    private let set: (Value) -> Void

    var value: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }

    init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.get = get
        self.set = set
    }
}

// MARK: - Equatable

extension BindingValue: Equatable where Value: Equatable {
    static func == (lhs: BindingValue<Value>, rhs: BindingValue<Value>) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Hashable

extension BindingValue: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

// MARK: - Helpers

extension BindingValue {
    var asBinding: Binding<Value> {
        Binding<Value>(get: get, set: set)
    }
}

extension BindingValue where Value == Bool {
    func toggle() {
        value.toggle()
    }
}

extension BindingValue {
    init<Root: AnyObject>(
        root: Root,
        default value: Value,
        get: @escaping (Root) -> Value,
        set: @escaping (Root, Value) -> Void
    ) {
        self.init { [weak root] in
            guard let root else {
                assertionFailure("Root is released")
                return value
            }

            return get(root)
        } set: { [weak root] newValue in
            guard let root else {
                assertionFailure("Root is released")
                return
            }

            return set(root, newValue)
        }
    }
}

// MARK: - Binding+

extension Binding {
    var asBindingValue: BindingValue<Value> {
        BindingValue(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}
