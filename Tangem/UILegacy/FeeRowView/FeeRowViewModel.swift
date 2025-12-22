//
//  FeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemFoundation

struct FeeRowViewModel: Identifiable, Hashable {
    var id: Int { hashValue }

    let option: FeeOption
    let components: LoadingResult<FormattedFeeComponents, any Error>
    let style: Style

    func hash(into hasher: inout Hasher) {
        hasher.combine(option)
        hasher.combine(style)

        switch components {
        case .loading:
            hasher.combine("loading")
        case .success(let value):
            hasher.combine(value)
        case .failure(let error):
            hasher.combine(error.localizedDescription)
        }
    }

    static func == (lhs: FeeRowViewModel, rhs: FeeRowViewModel) -> Bool {
        guard
            lhs.option == rhs.option,
            lhs.style == rhs.style
        else {
            return false
        }

        switch (lhs.components, rhs.components) {
        case (.loading, .loading):
            return true
        case (.success(let lhsValue), .success(let rhsValue)):
            return lhsValue == rhsValue
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

extension FeeRowViewModel {
    enum Style: Hashable {
        case plain
        case selectable(isSelected: BindingValue<Bool>)
    }
}
