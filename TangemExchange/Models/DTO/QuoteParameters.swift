//
//  QuoteParameters.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct QuoteParameters {
    public var fromTokenAddress: String
    public var toTokenAddress: String
    public var amount: String
    public var protocols: String?
    public var fee: String?
    public var gasLimit: String?
    public var complexityLevel: String?
    public var mainRouteParts: String?
    public var parts: String?
    public var gasPrice: String?

    public init(
        fromTokenAddress: String,
        toTokenAddress: String,
        amount: String,
        protocols: String? = nil,
        fee: String? = nil,
        gasLimit: String? = nil,
        complexityLevel: String? = nil,
        mainRouteParts: String? = nil,
        parts: String? = nil,
        gasPrice: String? = nil
    ) {
        self.fromTokenAddress = fromTokenAddress
        self.toTokenAddress = toTokenAddress
        self.amount = amount
        self.protocols = protocols
        self.fee = fee
        self.gasLimit = gasLimit
        self.complexityLevel = complexityLevel
        self.mainRouteParts = mainRouteParts
        self.parts = parts
        self.gasPrice = gasPrice
    }

    func parameters() -> [String: Any] {
        var params: [String: Any] = [
            "fromTokenAddress": fromTokenAddress,
            "toTokenAddress": toTokenAddress,
            "amount": amount,
        ]

        if let gasLimit = gasLimit {
            params["gasLimit"] = gasLimit
        }

        if let gasPrice = gasPrice {
            params["gasPrice"] = gasPrice
        }

        if let fee = fee {
            params["fee"] = fee
        }

        if let complexityLevel = complexityLevel {
            params["complexityLevel"] = complexityLevel
        }

        if let mainRouteParts = mainRouteParts {
            params["mainRouteParts"] = mainRouteParts
        }

        if let parts = parts {
            params["parts"] = parts
        }

        if let protocols = protocols {
            params["protocols"] = protocols
        }

        return params
    }
}
