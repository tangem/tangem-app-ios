//
//  FilterItem+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public enum FilterItemVariant: Sendable, Hashable, CaseIterable {
    case material
    case transparent
}

public enum FilterItemState: Sendable, Hashable {
    case inactive(label: String)
    case active(value: String, counter: Int? = nil)
    case loading
}

public extension FilterItem {
    typealias Variant = FilterItemVariant
}
