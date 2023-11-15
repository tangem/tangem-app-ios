//
//  ExpectedQuote.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpectedQuote: Hashable {
    public let provider: ExpressProvider
    public let state: State

    public var quote: ExpressQuote? {
        switch state {
        case .quote(let expressQuote):
            return expressQuote
        case .error, .notAvailable:
            return nil
        }
    }

    public enum State: Hashable {
        case quote(ExpressQuote)
        case error(String)
        case notAvailable
    }
}
