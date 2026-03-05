//
//  StepsFlowStepLinkedList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class StepsFlowStepLinkedList: LinkedList<StepsFlowStep> {
    func position(element: some StepsFlowStep) -> Position? {
        var current = head
        var index = 0
        var total = 0
        var nodeIndex: Int?

        while let currentNode = current {
            if currentNode.element.id == element.id {
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
