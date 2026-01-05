//
//  TokenFeeProviderMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

struct TokenFeeProviderMock: TokenFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { [] }
    func getFee(dataType: TokenFeeProviderDataType) async throws -> [BSDKFee] { [] }
}
