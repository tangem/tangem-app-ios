//
//  AVector.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    // Define AVector as a typealias for Array
    typealias AVector<Element> = [Element]

    /// Creates an empty array of the specified element type
    /// - Returns: An empty array of the specified element type
    static func empty<Element>() -> AVector<Element> { [] }

    /// Creates an array with the specified element type and initializes it with the given elements
    /// - Parameters:
    ///   - elements: The elements to initialize the array with
    /// - Returns: An array initialized with the given elements
    static func from<Element>(_ elements: Element...) -> AVector<Element> { elements }
}
