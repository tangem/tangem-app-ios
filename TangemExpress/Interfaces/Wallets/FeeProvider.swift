//
//  FeeProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public typealias ExpressFeeProvider = FeeProvider
public typealias ExpressFeeRequest = FeeRequest

public protocol FeeProvider {
    func estimatedFee(request: FeeRequest, amount: Decimal) async throws -> BSDKFee
    func estimatedFee(request: FeeRequest, estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee
    func transactionFee(request: FeeRequest, data: ExpressTransactionDataType) async throws -> BSDKFee
}

public struct FeeRequest {
    public let provider: ExpressProvider
    public let option: ExpressFee.Option
}
