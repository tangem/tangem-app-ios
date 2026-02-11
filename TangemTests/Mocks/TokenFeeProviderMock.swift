//
//  TokenFeeLoaderMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

struct TokenFeeLoaderMock: TokenFeeLoader {
    var allowsFeeSelection: Bool { false }
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { [] }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { [] }
}
