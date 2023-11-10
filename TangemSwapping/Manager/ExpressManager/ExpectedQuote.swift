//
//  ExpectedQuote.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpectedQuote: Hashable {
    let provider: ExpressProvider
    let state: State

    var quote: ExpressQuote? {
        switch state {
        case .quote(let expressQuote):
            return expressQuote
        case .error, .notAvailable:
            return nil
        }
    }

    enum State: Hashable {
        case quote(ExpressQuote)
        case error(String)
        case notAvailable
    }
}
