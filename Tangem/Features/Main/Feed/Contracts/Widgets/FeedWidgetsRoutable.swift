//
//  FeedWidgetsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedWidgetsRoutable: AnyObject {
    func openForYou()
    func openAddAccount(candidates: [FeedAccountCandidate])
}
