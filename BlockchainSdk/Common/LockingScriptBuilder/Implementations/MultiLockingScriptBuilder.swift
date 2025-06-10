//
//  MultiLockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MultiLockingScriptBuilder {
    private let decoders: [LockingScriptBuilder]

    init(decoders: [LockingScriptBuilder]) {
        self.decoders = decoders
    }
}

// MARK: - LockingScriptBuilder

extension MultiLockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        assert(address.rangeOfCharacter(from: .whitespacesAndNewlines) == nil, "Address contains whitespace")

        let results = decoders.map { decoder in
            Result { try decoder.lockingScript(for: address) }
        }

        guard let script = results.first(where: { $0.value != nil })?.value else {
            throw LockingScriptBuilderError.lockingScriptNotFound
        }

        return script
    }
}
