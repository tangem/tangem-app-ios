//
//  FeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FeeRowViewModel: Identifiable {
    let id = UUID()

    let option: FeeOption
    let subtitle: LoadingValue<String>
    let isSelected: BindingValue<Bool>

    init(
        option: FeeOption,
        subtitle: LoadingValue<String>,
        isSelected: BindingValue<Bool>
    ) {
        self.option = option
        self.subtitle = subtitle
        self.isSelected = isSelected
    }
}
