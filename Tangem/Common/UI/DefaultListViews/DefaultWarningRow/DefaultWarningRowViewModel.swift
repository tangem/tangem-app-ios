//
//  DefaultWarningRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultWarningRowViewModel {
    let icon: Image
    let title: String?
    let subtitle: String
    private(set) var detailsType: DetailsType?

    let action: (() -> ())?

    init(
        icon: Image,
        title: String?,
        subtitle: String,
        detailsType: DefaultWarningRowViewModel.DetailsType? = nil,
        action: (() -> ())? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.detailsType = detailsType
        self.action = action
    }

    mutating func update(detailsType: DetailsType?) {
        self.detailsType = detailsType
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
        hasher.combine(detailsType)
    }

    static func == (lhs: DefaultWarningRowViewModel, rhs: DefaultWarningRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultWarningRowViewModel: Identifiable {
    var id: Int { hashValue }
}
