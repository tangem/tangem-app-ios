//
//  Object+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Provides output similar to the native one, useful for `CustomStringConvertible` and
/// `CustomDebugStringConvertible` conformance.
/// ```
/// // Output example:
/// <UIDimmingView: 0x14622ddc0; frame = (-414 -736; 1242 2208); opaque = NO>
/// ```
public func objectDescription(
    _ object: AnyObject,
    userInfo: KeyValuePairs<AnyHashable, Any> = [:]
) -> String {
    let typeName = String(describing: type(of: object))
    let memoryAddress = String(describing: Unmanaged.passUnretained(object).toOpaque())
    let objectDescription = typeName + ": " + memoryAddress

    return ObjectDescriptionFormatter.format(objectDescription: objectDescription, userInfo: userInfo)
}

/// A simplified version of `objectDescription(_:userInfo:)` for use with non-class instances
public func objectDescription(
    _ description: String,
    userInfo: KeyValuePairs<AnyHashable, Any> = [:]
) -> String {
    return ObjectDescriptionFormatter.format(objectDescription: description, userInfo: userInfo)
}

// MARK: - Private implementation

private enum ObjectDescriptionFormatter {
    static func format(objectDescription: String, userInfo: KeyValuePairs<AnyHashable, Any>) -> String {
        let initialResult = objectDescription.isEmpty ? [] : [objectDescription]
        let description = userInfo.reduce(into: initialResult) { partialResult, pair in
            partialResult.append(String(describing: pair.key) + " = " + String(describing: pair.value))
        }

        return "<" + description.joined(separator: "; ") + ">"
    }
}
