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
    let isEnabled: Bool

    @Binding var isOn: Bool
    
    init(title: String, isEnabled: Bool = true, isOn: Binding<Bool>) {
        self.title = title
        self.isEnabled = isEnabled

        _isOn = isOn
    }
}

extension DefaultToggleRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(isEnabled)
        hasher.combine(isOn)
    }

    static func == (lhs: DefaultToggleRowViewModel, rhs: DefaultToggleRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension DefaultToggleRowViewModel: Identifiable {
    var id: Int { hashValue }
}
