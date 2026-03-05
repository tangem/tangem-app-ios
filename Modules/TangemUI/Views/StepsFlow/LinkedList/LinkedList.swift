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

    var nodes: [Node] {
        var result: [Node] = []
        var current = head

        while let node = current {
            result.append(node)
            current = node.next
        }

        return result
    }

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
        nodes.forEach { body($0.element) }
    }
}
