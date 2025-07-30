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
    typealias Step = HotOnboardingFlowStep
    typealias Node = LinkedListNode<Step>

    var currentStepId: AnyHashable {
        currentNode?.id
    }

    var hasProgressBar = false

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

// MARK: - NavBar

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

// MARK: - ProgressBar

extension HotOnboardingFlowBuilder {
    func setupProgress() {
        hasProgressBar = true

        flow.forEach { step in
            let progressValue: Double
            if let position = flow.position(element: step) {
                progressValue = Double(position.index + 1) / Double(position.total)
            } else {
                progressValue = 0
            }
            step.configureProgressBar(value: progressValue)
        }
    }
}

// MARK: - Helpers

extension HotOnboardingFlowBuilder {
    var navBarBackAction: HotOnboardingFlowNavBarAction {
        HotOnboardingFlowNavBarAction.back(handler: { [weak self] in
            self?.back()
        })
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
