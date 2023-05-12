//
//  DefaultRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

// [REDACTED_TODO_COMMENT]
struct DefaultRowViewModel {
    let title: String
    private(set) var detailsType: DetailsType?
    let action: (() -> Void)?

    /// - Parameters:
    ///   - title: Leading one line title
    ///   - details: Trailing one line text
    ///   - action: If the `action` is set that the row will be tappable and have chevron icon
    init(
        title: String,
        detailsType: DetailsType? = .none,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.detailsType = detailsType
        self.action = action
    }

    mutating func update(detailsType: DetailsType?) {
        self.detailsType = detailsType
    }
}

extension DefaultRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(detailsType)
        hasher.combine(action == nil)
    }

    static func == (lhs: DefaultRowViewModel, rhs: DefaultRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultRowViewModel: Identifiable {
    var id: Int { hashValue }
}

extension DefaultRowViewModel {
    enum DetailsType: Hashable {
        case text(_ string: String)
        case loader
        case icon(_ image: ImageType)
    }
}
