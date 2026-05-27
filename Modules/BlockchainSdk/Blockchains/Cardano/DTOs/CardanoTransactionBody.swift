//
//  CardanoTransactionBody.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import PotentCBOR

struct CardanoTransactionBody {
    let cbor: CBOR

    init?(cbor: CBOR) {
        guard case .array(let byteString) = cbor, let first = byteString.first else {
            return nil
        }

        self.cbor = CBOR.removingTag(Constants.stakingTag, from: first)
    }
}

extension CardanoTransactionBody {
    enum Constants {
        static let stakingTag: UInt64 = 258
    }
}
