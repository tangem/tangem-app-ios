//
//  LinkedListNode.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

class LinkedListNode<Element> {
    typealias Node = LinkedListNode<Element>

    let element: Element
    weak var previous: Node?
    var next: Node?

    init(element: Element) {
        self.element = element
    }
}
