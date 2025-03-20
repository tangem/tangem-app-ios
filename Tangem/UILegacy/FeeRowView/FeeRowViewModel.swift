//
//  FeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FeeRowViewModel: Identifiable, Hashable {
    var id: Int { hashValue }

    let option: FeeOption
    let components: LoadingValue<FormattedFeeComponents>
    let style: Style
}

extension FeeRowViewModel {
    enum Style: Hashable {
        case plain
        case selectable(isSelected: BindingValue<Bool>)
    }
}
