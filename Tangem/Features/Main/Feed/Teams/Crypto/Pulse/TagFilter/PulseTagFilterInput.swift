//
//  PulseTagFilterInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct PulseTagFilterInput {
    let selectedTagID: String?
    /// `nil` means the filter was cleared and the list goes back to the whole market.
    let onApply: (PulseTagSelection?) -> Void
}
