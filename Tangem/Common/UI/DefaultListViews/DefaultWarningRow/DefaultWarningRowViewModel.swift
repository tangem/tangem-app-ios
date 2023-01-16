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

    private(set) var leftView: AdditionalViewType?
    private(set) var rightView: AdditionalViewType?

    let action: (() -> ())?

    init(
        title: String? = nil,
        subtitle: String,
        leftView: DefaultWarningRowViewModel.AdditionalViewType? = nil,
        rightView: DefaultWarningRowViewModel.AdditionalViewType? = nil,
        action: (() -> ())? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leftView = leftView
        self.rightView = rightView
        self.action = action
    }

    mutating func update(leftView: AdditionalViewType?) {
        self.leftView = leftView
    }

    mutating func update(rightView: AdditionalViewType?) {
        self.rightView = rightView
    }
}

extension DefaultWarningRowViewModel {
    enum AdditionalViewType: Hashable {
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
