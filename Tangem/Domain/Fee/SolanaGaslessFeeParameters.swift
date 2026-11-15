//
//  SolanaGaslessFeeParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SolanaGaslessFeeParameters: FeeParameters {
    let feePayer: String
    let networkFee: BSDKFee
}
