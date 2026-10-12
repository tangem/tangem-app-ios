//
//  CollectiblesWelcomeRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol CollectiblesWelcomeRoutable: AnyObject {
    func openStories()
    func openLegalTerms(url: URL)
}
