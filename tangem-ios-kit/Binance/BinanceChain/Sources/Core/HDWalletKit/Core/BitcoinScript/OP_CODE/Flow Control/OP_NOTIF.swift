//
//  OP_NOTIF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct OpNotIf: OpCodeProtocol {
    public var value: UInt8 { return 0x64 }
    public var name: String { return "OP_NOTIF" }

    public func mainProcess(_ context: ScriptExecutionContext) throws {
        var value: Bool = false
        if context.shouldExecute {
            try context.assertStackHeightGreaterThanOrEqual(1)
            value = context.bool(at: -1)
            context.stack.removeLast()
        }
        context.conditionStack.append(!value)
    }
}
