//
//  SwappingApprovedDataModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingApprovedDataModel {
    public let data: Data
    public let tokenAddress: String

    /// The value which send for approve in WEI
    public let value: Decimal
}
