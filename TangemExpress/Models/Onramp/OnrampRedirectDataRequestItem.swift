//
//  OnrampRedirectDataRequestItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectDataRequestItem {
    public let quotesItem: OnrampQuotesRequestItem
    public let redirectSettings: OnrampRedirectSettings

    public init(
        quotesItem: OnrampQuotesRequestItem,
        redirectSettings: OnrampRedirectSettings
    ) {
        self.quotesItem = quotesItem
        self.redirectSettings = redirectSettings
    }
}
