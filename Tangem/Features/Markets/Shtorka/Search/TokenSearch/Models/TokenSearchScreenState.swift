//
//  TokenSearchScreenState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// [STUB] Delete this comment when implemented.
///
/// TokenSearchScreenState drives the View's layout:
///   .idle        — search bar is empty, show hints + recents
///   .searching   — user typed something, local results ready, API still loading
///   .results     — both local and API results available
///   .empty       — both sources returned zero results
///   .error       — API failed (local results may still be shown above the error block)
enum TokenSearchScreenState: Hashable {
    case idle
    case searching
    case results
    case empty
    case error
}
