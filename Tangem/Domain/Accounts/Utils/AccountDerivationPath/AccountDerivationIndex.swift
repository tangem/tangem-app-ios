//
//  AccountDerivationIndex.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum AccountDerivationIndex {
    static func nodeIndex(_ index: Int) throws -> UInt32 {
        let nodeIndex = try UInt32(raw: index)

        guard nodeIndex < Constants.hardenedOffset else {
            throw Error.outOfNodeRange(index)
        }

        return nodeIndex
    }
}

// MARK: - Error

extension AccountDerivationIndex {
    enum Error: Swift.Error, LocalizedError {
        case outOfNodeRange(Int)

        var errorDescription: String? {
            switch self {
            case .outOfNodeRange(let index):
                return "Derivation index \(index) is past the range of a derivation node."
            }
        }
    }
}

// MARK: - Constants

private extension AccountDerivationIndex {
    enum Constants {
        static let hardenedOffset: UInt32 = 0x8000_0000
    }
}
