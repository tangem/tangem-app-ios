//
//  ContentState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum ContentState<Data> {
    case loading
    case empty
    case loaded(_ content: Data)
    case error(error: Error)

    var isEmpty: Bool {
        if case .empty = self {
            return true
        }

        return false
    }
}
