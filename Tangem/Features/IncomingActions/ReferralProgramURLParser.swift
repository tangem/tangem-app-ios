//
//  ReferralProgramURLParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ReferralProgramURLParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        guard url.absoluteString.contains("test") else { return nil } // [REDACTED_TODO_COMMENT]
        return .referralProgram
    }
}
