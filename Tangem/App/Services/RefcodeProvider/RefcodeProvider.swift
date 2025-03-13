//
//  RefcodeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum Refcode: String, CaseIterable {
    case ring
    case partner
    case changeNow = "ChangeNow"
}

protocol RefcodeProvider {
    func getRefcode() -> Refcode?
}
