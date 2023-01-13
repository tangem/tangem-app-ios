//
//  DefaultWarningRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultWarningRowViewModel {
    let title: String?
    let subtitle: String

    private(set) var leftView: DetailsType?
    private(set) var rightView: DetailsType?

    init(
        title: String?,
        subtitle: String,
        leftView: DefaultWarningRowViewModel.DetailsType? = nil,
        rightView: DefaultWarningRowViewModel.DetailsType? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leftView = leftView
        self.rightView = rightView
    }

    mutating func update(leftView: DetailsType?) {
        self.leftView = leftView
    }

    mutating func update(rightView: DetailsType?) {
        self.rightView = rightView
    }
}

extension DefaultWarningRowViewModel {
    enum DetailsType: Hashable {
        case icon(_ image: Image)
        case loader

        func hash(into hasher: inout Hasher) {
            switch self {
            case .loader:
                hasher.combine("loader")
            case .icon:
                hasher.combine("icon")
            }
        }
    }
}

extension DefaultWarningRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(leftView)
        hasher.combine(rightView)
    }

    static func == (lhs: DefaultWarningRowViewModel, rhs: DefaultWarningRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultWarningRowViewModel: Identifiable {
    var id: Int { hashValue }
}
