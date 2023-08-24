//
//  FetchMore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FetchMore: Identifiable {
    let id: String
    let start: () -> Void
}
