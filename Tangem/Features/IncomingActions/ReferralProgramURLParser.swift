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
        guard url.absoluteString == Constants.referralURLString else { return nil }
        return .referralProgram
    }
}

private extension ReferralProgramURLParser {
    enum Constants {
        static let referralURLString = "tangem://referral"
    }
}
