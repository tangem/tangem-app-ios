//
//  DefaultWarningRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct DefaultWarningRowViewModel {
    let icon: ImageType
    let title: String?
    let subtitle: String
    private(set) var detailsType: DetailsType?

    let action: () -> ()

    init(
        icon: ImageType,
        title: String?,
        subtitle: String,
        detailsType: DefaultWarningRowViewModel.DetailsType? = nil,
        action: @escaping () -> ()
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
        case icon(_ image: ImageType)
        case loader
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
