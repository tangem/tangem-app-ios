//
//  ALPH+Hint.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A value type representing a hint, backed by an integer.
    struct Hint: Hashable {
        // MARK: - Properties

        /// The underlying integer value of the hint
        let value: Int

        // MARK: - Computed Properties

        /// Returns true if the hint represents an asset type
        var isAssetType: Bool {
            (value & 1) == 1
        }

        // MARK: - Static Methods

        /// Creates a hint from an asset output
        /// - Parameter assetOutput: The asset output to create the hint from
        /// - Returns: A new hint representing the asset output
        static func from(_ assetOutput: AssetOutput) -> Hint {
            ofAsset(assetOutput.lockupScript.scriptHint)
        }

        /// Creates a hint from a script hint
        /// - Parameter scriptHint: The script hint to create the hint from
        /// - Returns: A new hint representing the script hint
        static func ofAsset(_ scriptHint: ScriptHint) -> Hint {
            Hint(value: scriptHint.value)
        }

        // MARK: - Serialization

        /// Serialization/deserialization implementation using 4-byte encoding
        static var serde: ALPH.AnySerde<ALPH.Hint> {
            ALPH.BytesSerde(length: 4)
                .xmap(
                    to: { Hint(value: Bytes.toIntUnsafe($0)) },
                    from: { Bytes.from($0.value) }
                )
        }
    }
}
