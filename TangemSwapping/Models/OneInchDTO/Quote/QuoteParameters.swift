//
//  QuoteParameters.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct QuoteParameters: Encodable {
    public var src: String
    public var dst: String
    public var amount: String
    public var protocols: String?
    public var fee: String?
    public var gasLimit: String?
    public var complexityLevel: String?
    public var mainRouteParts: String?
    public var parts: String?
    public var gasPrice: String?

    public init(
        src: String,
        dst: String,
        amount: String,
        protocols: String? = nil,
        fee: String? = nil,
        gasLimit: String? = nil,
        complexityLevel: String? = nil,
        mainRouteParts: String? = nil,
        parts: String? = nil,
        gasPrice: String? = nil
    ) {
        self.src = src
        self.dst = dst
        self.amount = amount
        self.protocols = protocols
        self.fee = fee
        self.gasLimit = gasLimit
        self.complexityLevel = complexityLevel
        self.mainRouteParts = mainRouteParts
        self.parts = parts
        self.gasPrice = gasPrice
    }
}
