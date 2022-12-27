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
    @Binding var isSelected: Bool

    init(title: String, subtitle: String?, isSelected: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        _isSelected = isSelected
    }
}

extension DefaultSelectableRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(isSelected)
    }

    static func == (lhs: DefaultSelectableRowViewModel, rhs: DefaultSelectableRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultSelectableRowViewModel: Identifiable {
    var id: Int { hashValue }
}
