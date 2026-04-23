//
//  Alephium+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing a script hint in the Alephium blockchain
    /// Script hints are used to optimize script validation by providing a quick way to check if a script matches
    struct ScriptHint {
        /// The integer value of the script hint
        let value: Int

        /// Creates a new script hint with the given value
        /// - Parameter value: The integer value to use for the script hint
        init(value: Int) {
            self.value = value
        }

        /// Creates a script hint from a hash of the given data
        /// - Parameter data: The data to hash
        /// - Returns: A new ScriptHint instance with a value derived from the data hash
        static func fromHash(_ data: Data) -> ScriptHint {
            return fromHash(DjbHash().intHash(data.bytes))
        }

        /// Creates a script hint from a given hash value
        /// - Parameter hash: The integer hash value
        /// - Returns: A new ScriptHint instance with a value derived from the hash
        /// The value is created by [REDACTED_AUTHOR]
        static func fromHash(_ hash: Int) -> ScriptHint {
            return ScriptHint(value: hash | 1)
        }
    }
}
