//
//  SegmentedControl+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public extension SegmentedControl {
    struct Item: Identifiable, Hashable {
        public let id: Tag
        public let title: String

        public init(id: Tag, title: String) {
            self.id = id
            self.title = title
        }
    }
}
