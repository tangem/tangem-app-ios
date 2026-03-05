//
//  StepsFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

open class StepsFlowBuilder {
    public typealias Step = any StepsFlowStep

    typealias Flow = StepsFlowStepLinkedList
    typealias Node = LinkedListNode<Step>

    var steps: [Step] { flow.nodes.map(\.element) }

    var currentPosition: Flow.Position? {
        guard let currentNode else { return nil }
        return flow.position(element: currentNode.element)
    }

    let currentNodeSubject = CurrentValueSubject<Node?, Never>(nil)

    private var currentNode: Node? { currentNodeSubject.value }

    private let flow = Flow()

    public init() {
        setupFlow()
        startFlow()
    }

    open func setupFlow() {}
}

// MARK: - Private methods

private extension StepsFlowBuilder {
    func startFlow() {
        guard let head = flow.head else {
            return
        }
        setup(currentNode: head)
    }

    func setup(currentNode: Node) {
        currentNodeSubject.send(currentNode)
    }
}

// MARK: - Flow commands

public extension StepsFlowBuilder {
    func next() {
        guard
            let currentNode,
            let nextNode = currentNode.next
        else {
            return
        }
        setup(currentNode: nextNode)
    }

    func back() {
        guard
            let currentNode,
            let previousNode = currentNode.previous
        else {
            return
        }
        setup(currentNode: previousNode)
    }
}

// MARK: - Step commands

public extension StepsFlowBuilder {
    func append(step: Step) {
        flow.append(step)
    }
}
