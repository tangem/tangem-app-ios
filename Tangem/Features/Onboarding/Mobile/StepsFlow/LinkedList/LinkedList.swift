//
//  LinkedList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

class LinkedList<Element> {
    typealias Node = LinkedListNode<Element>

    private(set) var head: Node?
    private(set) var tail: Node?

    func append(_ element: Element) {
        let node = Node(element: element)

        if let tail {
            tail.next = node
            node.previous = tail
        } else {
            head = node
        }

        tail = node
    }

    func forEach(_ body: (Element) -> Void) {
        var current = head
        while let node = current {
            body(node.element)
            current = node.next
        }
    }
}
