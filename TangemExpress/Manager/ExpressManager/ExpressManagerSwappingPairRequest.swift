//
//  ExpressManagerSwappingPairRequest.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct ExpressManagerSwappingPairRequest {
    public let amount: Decimal
    public let feeOption: ExpressFee.Option
    public let approvePolicy: ApprovePolicy
    public let operationType: ExpressOperationType
}
