//
//  ALPH+SameAsPrevious.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing a same-as-previous unlock script in the Alephium blockchain
    struct SameAsPrevious: UnlockScript {
        // MARK: - Properties

        /// The public key data for the unlock script
        var publicKeyData: Data = .init()

        // MARK: - Initializers

        /// Creates a new same-as-previous unlock script
        /// - Parameter publicKeyData: The public key data for the unlock script
        init(publicKeyData: Data = .init()) {
            self.publicKeyData = publicKeyData
        }

        // MARK: - UnlockScript Conformance

        /// Serialization/deserialization implementation
        static var serde: ALPH.AnySerde<ALPH.SameAsPrevious> {
            ALPH.BytesSerde(length: 0)
                .xmap(
                    to: { _ in SameAsPrevious() },
                    from: { _ in Data() }
                )
        }
    }
}
