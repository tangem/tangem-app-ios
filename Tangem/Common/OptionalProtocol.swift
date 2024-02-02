//
//  OptionalProtocol.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// A lightweight interface that allows making extensions with generic constraints for the `Swift.Optional` type.
protocol OptionalProtocol {
    associatedtype Wrapped

    var wrapped: Wrapped? { get }
}

extension Optional: OptionalProtocol {
    var wrapped: Wrapped? { self }
}
