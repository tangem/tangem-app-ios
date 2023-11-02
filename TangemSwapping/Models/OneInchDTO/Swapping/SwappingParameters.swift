//
//  SwappingParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingParameters: Encodable {
    public var src: String
    public var dst: String
    public var amount: String
    public var from: String
    public var slippage: Int
    public var disableEstimate: Bool?
    public var protocols: String?
    public var receiver: String?
    public var referrer: String?
    public var fee: String?
    public var burnChi: Bool?
    public var allowPartialFill: Bool?
    public var parts: String?
    public var mainRouteParts: String?
    public var connectorTokens: String?
    public var complexityLevel: String?
    public var gasLimit: String?
    public var gasPrice: String?

    public init(
        src: String,
        dst: String,
        amount: String,
        from: String,
        slippage: Int,
        disableEstimate: Bool? = nil,
        protocols: String? = nil,
        receiver: String? = nil,
        referrer: String? = nil,
        fee: String? = nil,
        burnChi: Bool? = nil,
        allowPartialFill: Bool? = nil,
        parts: String? = nil,
        mainRouteParts: String? = nil,
        connectorTokens: String? = nil,
        complexityLevel: String? = nil,
        gasLimit: String? = nil,
        gasPrice: String? = nil
    ) {
        self.src = src
        self.dst = dst
        self.amount = amount
        self.from = from
        self.slippage = slippage
        self.disableEstimate = disableEstimate
        self.protocols = protocols
        self.receiver = receiver
        self.referrer = referrer
        self.fee = fee
        self.burnChi = burnChi
        self.allowPartialFill = allowPartialFill
        self.parts = parts
        self.mainRouteParts = mainRouteParts
        self.connectorTokens = connectorTokens
        self.complexityLevel = complexityLevel
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
    }
}
