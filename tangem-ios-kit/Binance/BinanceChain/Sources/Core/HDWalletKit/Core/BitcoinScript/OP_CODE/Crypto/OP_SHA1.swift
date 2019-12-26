//
//  OP_SHA1.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation
import CryptoSwift

// The input is hashed using SHA-1.
public struct OpSha1: OpCodeProtocol {
    public var value: UInt8 { return 0xa7 }
    public var name: String { return "OP_SHA1" }

    // input : in
    // output : hash
    public func mainProcess(_ context: ScriptExecutionContext) throws {
        try context.assertStackHeightGreaterThanOrEqual(1)

        let data: Data = context.stack.removeLast()
        let hash: Data = data.sha1()
        context.stack.append(hash)
    }
}
