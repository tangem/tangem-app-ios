//
//  PolymarketLegalNotice.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A legal footnote a Polymarket screen asks for.
public enum PolymarketLegalNotice {
    /// The user agrees with the terms by proceeding.
    case termsAgreement
    /// The terms are already accepted and still apply.
    case termsAlreadyAccepted
}
