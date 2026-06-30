//
//  LinkedMarketingBannerProviding.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol LinkedMarketingBannerProviding: AnyObject {
    var linkedBannersPublisher: AnyPublisher<[MarketingBanner], Never> { get }
}
