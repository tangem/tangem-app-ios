//
//  ExchangeSDK.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

public struct ExchangeSdk {
    public static func buildOneInchExchangeService(isDebug: Bool) -> ExchangeServiceProtocol {
        return ExchangeService(isDebug: isDebug)
    }
    
    public static func buildOneInchLimitService(isDebug: Bool) -> LimitOrderServiceProtocol {
        return LimitOrderService(isDebug: isDebug)
    }
}
