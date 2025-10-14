//
//  LinkedList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
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
}

extension LinkedList {
    func forEach(_ body: (Element) -> Void) {
        var current = head
        while let node = current {
            body(node.element)
            current = node.next
        }
    }
}

extension LinkedList where Element: AnyObject {
    func position(element: Element) -> Position? {
        var current = head
        var index = 0
        var total = 0
        var nodeIndex: Int?

        while let currentNode = current {
            if currentNode.element === element {
                nodeIndex = index
            }

            index += 1
            total += 1
            current = currentNode.next
        }

        guard let nodeIndex else {
            return nil
        }

        return Position(index: nodeIndex, total: total)
    }

    struct Position {
        let index: Int
        let total: Int
    }
}

class LinkedListNode<Element> {
    typealias Id = AnyHashable
    typealias Node = LinkedListNode<Element>

    let element: Element
    weak var previous: Node?
    var next: Node?

    var id: Id {
        ObjectIdentifier(self)
    }

    init(element: Element) {
        self.element = element
    }
}
