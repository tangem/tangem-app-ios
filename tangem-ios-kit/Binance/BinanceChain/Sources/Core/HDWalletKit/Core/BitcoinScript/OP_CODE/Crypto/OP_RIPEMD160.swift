//
//  OP_RIPEMD160.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

// The input is hashed using RIPEMD-160.
public struct OpRipemd160: OpCodeProtocol {
    public var value: UInt8 { return 0xa6 }
    public var name: String { return "OP_RIPEMD160" }

    // input : in
    // output : hash
    public func mainProcess(_ context: ScriptExecutionContext) throws {
        try context.assertStackHeightGreaterThanOrEqual(1)

        let data: Data = context.stack.removeLast()
        let hash: Data = RIPEMD160.hash(data)
        context.stack.append(hash)
    }
}
