//
//  HotAccessCodeStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotAccessCodeStorage: AnyObject {
    func getWrongAccessCodeStore() -> HotWrongAccessCodeStore
    func storeWrongAccessCodeAttempt(date: Date)
    func clearWrongAccessCodeStore()
}
