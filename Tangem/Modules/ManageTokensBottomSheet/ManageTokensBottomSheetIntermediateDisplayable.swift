//
//  ManageTokensBottomSheetIntermediateDisplayable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Represents an intermediate entity in the chain of Manage Tokens bottom sheet displayables.
protocol ManageTokensBottomSheetIntermediateDisplayable: ManageTokensBottomSheetDisplayable {
    /// Next chain member, up the chain.
    /* weak */ var nextManageTokensBottomSheetDisplayable: ManageTokensBottomSheetDisplayable? { get }
}
