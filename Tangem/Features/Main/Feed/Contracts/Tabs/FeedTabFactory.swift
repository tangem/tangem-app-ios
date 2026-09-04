//
//  FeedTabFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedTabFactory {
    func makeTab(navigation: any FeedRoutable) -> FeedTab
}
