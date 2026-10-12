//
//  InjectedWrapper.swift
//  IdealApp
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

@propertyWrapper
struct Injected<T, P> {
    private let keyPath: KeyPath<InjectedValues, P>

    var wrappedValue: T { InjectedValues[keyPath] as! T }

    init(_ keyPath: KeyPath<InjectedValues, P>) {
        self.keyPath = keyPath
    }
}
