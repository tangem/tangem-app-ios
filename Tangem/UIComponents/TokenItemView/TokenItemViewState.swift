//
//  TokenItemViewState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TokenItemViewState {
    case notLoaded
    case noDerivation
    case loading
    case loaded
    case noAccount(message: String)
    case networkError(Error)
}
