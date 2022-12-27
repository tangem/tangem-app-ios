//
//  EIP712SignTypedDataProvider.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol SignTypedDataProviding {
    func permitData(for currency: Currency, dataModel: SignTypedDataPermitDataModel, deadline: Date) async throws -> String
}

public struct SignTypedDataPermitDataModel {
    public let walletAddress: String
    public let spenderAddress: String
    public let amount: Decimal
}
