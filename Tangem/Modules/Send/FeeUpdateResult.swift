//
//  FeeUpdateResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

typealias FeeUpdateResult = Result<(oldFee: Amount?, newFee: Amount), Error>
