//
//  ReferralParam.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A referral parameter as a link actually delivers it. OneLink writes an unset one out as an empty string or
/// as the literal `null`, and a value like that must never reach the stored referral state — it would look
/// like an existing referral forever.
enum ReferralParam {
    static func normalized(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmed.isNotEmpty,
              trimmed != Constants.unset
        else {
            return nil
        }

        return trimmed
    }

    private enum Constants {
        static let unset = "null"
    }
}
