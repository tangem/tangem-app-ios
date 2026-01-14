//
//  MarketsTokenNewsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MarketsTokenNewsRoutable: AnyObject {
    func openNews(by id: NewsId)
    func openAllNews()
}
