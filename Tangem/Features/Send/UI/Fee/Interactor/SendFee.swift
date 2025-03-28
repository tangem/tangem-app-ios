//
//  SendFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Fee
import TangemFoundation

struct SendFee: Hashable {
    let option: FeeOption
    let value: LoadingValue<Fee>
}
