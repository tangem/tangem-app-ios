//
//  ForYouRoutable.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol ForYouRoutable: AnyObject {
    @MainActor
    func openTokenSummary(tokenItem: TokenItem)
}
