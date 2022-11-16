//
//  SwapParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwapParameters {
    public var fromTokenAddress: String
    public var toTokenAddress: String
    public var amount: String
    public var fromAddress: String
    public var slippage: Int
    public var disableEstimate: Bool?
    public var protocols: String?
    public var destReceiver: String?
    public var referrerAddress: String?
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
        fromTokenAddress: String,
        toTokenAddress: String,
        amount: String,
        fromAddress: String,
        slippage: Int,
        disableEstimate: Bool? = nil,
        protocols: String? = nil,
        destReceiver: String? = nil,
        referrerAddress: String? = nil,
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
        self.fromTokenAddress = fromTokenAddress
        self.toTokenAddress = toTokenAddress
        self.amount = amount
        self.fromAddress = fromAddress
        self.slippage = slippage
        self.disableEstimate = disableEstimate
        self.protocols = protocols
        self.destReceiver = destReceiver
        self.referrerAddress = referrerAddress
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

    func parameters() -> [String: Any] {
        var params: [String: Any] = [
            "fromTokenAddress": fromTokenAddress,
            "toTokenAddress": toTokenAddress,
            "amount": amount,
            "fromAddress": fromAddress,
            "slippage": "\(slippage)",
        ]
        if let disableEstimate = disableEstimate {
            params["disableEstimate"] = disableEstimate
        }

        if let referrerAddress = referrerAddress {
            params["referrerAddress"] = referrerAddress
        }

        if let allowPartialFill = allowPartialFill {
            params["allowPartialFill"] = allowPartialFill
        }

        if let gasLimit = gasLimit {
            params["gasLimit"] = gasLimit
        }

        if let gasPrice = gasPrice {
            params["gasPrice"] = gasPrice
        }

        if let protocols = protocols {
            params["protocols"] = protocols
        }

        if let destReceiver = destReceiver {
            params["destReceiver"] = destReceiver
        }

        if let fee = fee {
            params["fee"] = fee
        }

        if let burnChi = burnChi {
            params["burnChi"] = burnChi
        }

        if let parts = parts {
            params["parts"] = parts
        }

        if let mainRouteParts = mainRouteParts {
            params["mainRouteParts"] = mainRouteParts
        }

        if let complexityLevel = complexityLevel {
            params["complexityLevel"] = complexityLevel
        }
        return params
    }
}
