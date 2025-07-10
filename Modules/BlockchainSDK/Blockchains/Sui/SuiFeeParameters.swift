//
// SuiFeeParameters.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SuiFeeParameters: FeeParameters {
    let gasPrice: Decimal
    let gasBudget: Decimal
}
