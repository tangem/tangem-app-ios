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

    @Binding var isOn: Bool

    init(title: String, isDisabled: Bool = false, isOn: Binding<Bool>) {
        self.title = title
        self.isDisabled = isDisabled

        _isOn = isOn
    }

    /// Method for update `isOn` binding property
    /// Use this method when you should change toggle state from external place
    /// For instance, in case when you turn off toggle after user accepted alert
    /// `mutating` is reqiured that recreate ViewModel for rendering view
    mutating func update(isOn: Binding<Bool>) {
        _isOn = isOn
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
