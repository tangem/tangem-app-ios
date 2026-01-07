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
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { [] }
    func getFee(dataType: TokenFeeLoaderDataType) async throws -> [BSDKFee] { [] }
}

struct TokenFeeProviderMock: TokenFeeProvider {
    var fees: [TokenFee] { [] }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { .just(output: fees) }
    func reloadFees(request: TokenFeeProviderFeeRequest) {}
}
