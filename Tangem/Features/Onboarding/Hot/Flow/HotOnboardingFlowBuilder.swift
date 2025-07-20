//
//  HotOnboardingFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class HotOnboardingFlowBuilder: ObservableObject {
    typealias Step = any HotOnboardingFlowStep
    typealias Node = LinkedListNode<Step>

    var hasProgressBar: Bool { false }

    @ViewBuilder
    var content: some View {
        if let currentNode, let cachedView = cache[currentNode.id] {
            cachedView
        } else {
            EmptyView()
        }
    }

    let flow = LinkedList<Step>()

    @Published private var currentNode: Node?

    private var cache: [LinkedListNode.Id: AnyView] = [:]

    init() {
        setupFlow()
        startFlow()
    }

    func setupFlow() {}
}

// MARK: - Flow

private extension HotOnboardingFlowBuilder {
    func startFlow() {
        guard let head = flow.head else {
            return
        }
        addCache(node: head)
        currentNode = head
    }
}

// MARK: - Navigation

extension HotOnboardingFlowBuilder {
    func back() {
        guard
            let currentNode,
            let previousNode = currentNode.previous
        else {
            return
        }
        removeCache(node: currentNode)
        self.currentNode = previousNode
    }

    func next() {
        guard
            let currentNode,
            let nextNode = currentNode.next
        else {
            return
        }
        addCache(node: nextNode)
        self.currentNode = nextNode
    }
}

// MARK: - Progress

extension HotOnboardingFlowBuilder {
    func progressValue(node: Node) -> Double {
        if let postion = flow.position(node: node) {
            return Double(postion.index / postion.total)
        } else {
            return 0
        }
    }
}

// MARK: - Cache

private extension HotOnboardingFlowBuilder {
    func addCache(node: Node) {
        let view = node.element.buildWithTransformations()
        addCache(key: node.id, value: view)
    }

    func addCache(key: AnyHashable, value: any View) {
        cache[key] = AnyView(value)
    }

    func removeCache(node: Node) {
        cache.removeValue(forKey: node.id)
    }
}
