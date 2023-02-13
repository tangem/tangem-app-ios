//
//  DefaultSelectableRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultSelectableRowViewModel {
    let title: String
    let subtitle: String?
    let isSelected: () -> Binding<Bool>

    init(title: String, subtitle: String?, isSelected: @autoclosure @escaping () -> Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
    }
}

extension DefaultSelectableRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
    }

    static func == (lhs: DefaultSelectableRowViewModel, rhs: DefaultSelectableRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultSelectableRowViewModel: Identifiable {
    var id: Int { hashValue }
}
