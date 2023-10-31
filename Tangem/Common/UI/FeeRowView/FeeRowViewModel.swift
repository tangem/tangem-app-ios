//
//  FeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FeeRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let option: FeeOption
    let subtitle: String
    let isSelected: BindingValue<Bool>

    init(
        option: FeeOption,
        subtitle: String,
        isSelected: BindingValue<Bool>
    ) {
        self.option = option
        self.subtitle = subtitle
        self.isSelected = isSelected
    }
}

extension FeeOption {
    var icon: ImageType {
        switch self {
        case .market:
            return Assets.marketFeeIcon
        case .fast:
            return Assets.fastFeeIcon
        }
    }

    var title: String {
        switch self {
        case .market:
            return "Market"
        case .fast:
            return "Fast"
        }
    }
}
