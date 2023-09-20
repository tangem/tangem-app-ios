//
//  FetchMore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct FetchMore: Identifiable {
    public let id: String
    public let start: () -> Void

    public init(id: String = UUID().uuidString, start: @escaping () -> Void) {
        self.id = id
        self.start = start
    }
}
