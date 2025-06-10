//
//  Alephium+GroupIndex.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing a group index in the Alephium blockchain
    struct GroupIndex: Hashable {
        /// The underlying integer value of the group index
        let value: Int

        /// Creates a new group index with the specified value
        /// - Parameter value: The integer value for the group index
        init(_ value: Int) {
            self.value = value
        }

        // MARK: - Static Properties

        /// Serialization/deserialization implementation
        static var serde: ALPH.AnySerde<ALPH.GroupIndex> {
            ALPH.BytesSerde(length: 4)
                .xmap(
                    to: { GroupIndex(Bytes.toIntUnsafe($0)) },
                    from: { Bytes.from($0.value) }
                )
        }
    }
}

extension ALPH.GroupIndex: CustomStringConvertible {
    var description: String {
        "GroupIndex(\(value))"
    }
}
