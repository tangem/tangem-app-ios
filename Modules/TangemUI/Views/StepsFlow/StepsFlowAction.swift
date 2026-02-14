//
//  StepsFlowAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum StepsFlowAction {
    typealias Node = LinkedListNode<any StepsFlowStep>

    case push(Node)
    case pop(Node)

    var node: Node {
        switch self {
        case .push(let node): node
        case .pop(let node): node
        }
    }
}
