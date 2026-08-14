//
//  DisplayPolicy.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct DisplayPolicy: Equatable {
    public enum Kind: String, Equatable {
        case always
        case once
    }

    public enum Scope: String, Equatable {
        case device
        case wallet
    }

    public let type: Kind
    public let scope: Scope?
    public let resetOnVersion: Bool?

    public init(type: Kind, scope: Scope? = nil, resetOnVersion: Bool? = nil) {
        self.type = type
        self.scope = scope
        self.resetOnVersion = resetOnVersion
    }

    public static let always = DisplayPolicy(type: .always)

    public static func once(scope: Scope, resetOnVersion: Bool) -> DisplayPolicy {
        DisplayPolicy(type: .once, scope: scope, resetOnVersion: resetOnVersion)
    }
}
