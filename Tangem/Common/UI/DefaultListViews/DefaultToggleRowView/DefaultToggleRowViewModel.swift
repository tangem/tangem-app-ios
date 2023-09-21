//
//  DefaultToggleRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultToggleRowViewModel {
    let title: String
    let isDisabled: Bool
    let isOn: BindingValue<Bool>

    init(title: String, isDisabled: Bool = false, isOn: BindingValue<Bool>) {
        self.title = title
        self.isDisabled = isDisabled
        self.isOn = isOn
    }
}

extension DefaultToggleRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(isDisabled)
        hasher.combine(isOn)
    }

    static func == (lhs: DefaultToggleRowViewModel, rhs: DefaultToggleRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultToggleRowViewModel: Identifiable {
    var id: Int { hashValue }
}
