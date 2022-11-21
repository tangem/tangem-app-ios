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
    let title: String
    let subtitle: String
    let detailsType: DetailsType?

    let action: () -> ()

    init(
        icon: Image,
        title: String,
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
}

extension DefaultWarningRowViewModel {
    enum DetailsType {
        case icon(_ image: Image)
        case loader
    }
}

extension DefaultWarningRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
    }

    static func == (lhs: DefaultWarningRowViewModel, rhs: DefaultWarningRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultWarningRowViewModel: Identifiable {
    var id: Int { hashValue }
}
