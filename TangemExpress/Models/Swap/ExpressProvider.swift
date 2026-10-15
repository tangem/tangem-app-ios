//
//  ExpressProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressProvider: Hashable {
    public typealias Id = String

    public let id: Id
    public let name: String
    public let type: ExpressProviderType
    public let exchangeOnlyWithinSingleAddress: Bool
    public let imageURL: URL?
    public let termsOfUse: URL?
    public let privacyPolicy: URL?
    public let recommended: Bool?
    public let slippage: Decimal?
    public let isCustomSlippageSupported: Bool

    public init(
        id: Id,
        name: String,
        type: ExpressProviderType,
        exchangeOnlyWithinSingleAddress: Bool,
        imageURL: URL?,
        termsOfUse: URL?,
        privacyPolicy: URL?,
        recommended: Bool?,
        slippage: Decimal?,
        isCustomSlippageSupported: Bool
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.exchangeOnlyWithinSingleAddress = exchangeOnlyWithinSingleAddress
        self.imageURL = imageURL
        self.termsOfUse = termsOfUse
        self.privacyPolicy = privacyPolicy
        self.recommended = recommended
        self.slippage = slippage
        self.isCustomSlippageSupported = isCustomSlippageSupported
    }
}
