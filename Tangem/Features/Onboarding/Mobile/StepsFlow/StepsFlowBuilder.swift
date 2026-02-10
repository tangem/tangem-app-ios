//
//  StepsFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

class StepsFlowBuilder {
    typealias Flow = StepsFlowStepLinkedList
    typealias Step = any StepsFlowStep
    typealias Node = LinkedListNode<Step>

    var actionPublisher: AnyPublisher<StepsFlowAction?, Never> {
        actionSubject.eraseToAnyPublisher()
    }

    var currentPosition: Flow.Position? {
        guard let action = actionSubject.value else { return nil }
        return flow.position(element: action.node.element)
    }

    private var currentNode: Node? { actionSubject.value?.node }

    private let flow = Flow()
    private let actionSubject = CurrentValueSubject<StepsFlowAction?, Never>(nil)

    init() {
        setupFlow()
        startFlow()
    }

    func setupFlow() {}
}

// MARK: - Private methods

private extension StepsFlowBuilder {
    func startFlow() {
        guard let head = flow.head else {
            return
        }
        setup(action: .push(head))
    }

    func setup(action: StepsFlowAction) {
        actionSubject.send(action)
    }
}

// MARK: - Flow commands

extension StepsFlowBuilder {
    func next() {
        guard
            let currentNode,
            let nextNode = currentNode.next
        else {
            return
        }
        setup(action: .push(nextNode))
    }

    func back() {
        guard
            let currentNode,
            let previousNode = currentNode.previous
        else {
            return
        }
        setup(action: .pop(previousNode))
    }
}

// MARK: - Step commands

extension StepsFlowBuilder {
    func append(step: Step) {
        flow.append(step)
    }
}
