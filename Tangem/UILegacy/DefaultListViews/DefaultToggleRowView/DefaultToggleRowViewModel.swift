//
//  DefaultToggleRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultToggleRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: String
    let isDisabled: Bool
    let isOn: BindingValue<Bool>
    let accessibilityIdentifier: String?

    init(title: String, isDisabled: Bool = false, accessibilityIdentifier: String? = nil, isOn: BindingValue<Bool>) {
        self.title = title
        self.isDisabled = isDisabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isOn = isOn
    }
}
