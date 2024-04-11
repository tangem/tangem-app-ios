//
//  FeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FeeRowViewModel: Identifiable {
    var id: Int {
        hashValue
    }

    let option: FeeOption
    let isSelected: BindingValue<Bool>
    let hasIssues: BindingValue<Bool>

    var cryptoAmount: String? {
        switch formattedFeeComponents {
        case .loading:
            return ""
        case .loaded(let value):
            return value?.cryptoFee
        case .failedToLoad:
            return AppConstants.dashSign
        }
    }

    var fiatAmount: String? {
        switch formattedFeeComponents {
        case .loading, .failedToLoad:
            // Corresponding UI will be displayed by the cryptoAmount field
            return nil
        case .loaded(let value):
            return value?.fiatFee
        }
    }

    var isLoading: Bool {
        formattedFeeComponents.isLoading
    }

    private let formattedFeeComponents: LoadingValue<FormattedFeeComponents?>

    init(
        option: FeeOption,
        formattedFeeComponents: LoadingValue<FormattedFeeComponents?>,
        isSelected: BindingValue<Bool>,
        hasIssues: BindingValue<Bool> = .init(get: { false }, set: { _ in })
    ) {
        self.option = option
        self.formattedFeeComponents = formattedFeeComponents
        self.isSelected = isSelected
        self.hasIssues = hasIssues
    }
}

extension FeeRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(option)
        hasher.combine(formattedFeeComponents.isLoading)
        hasher.combine(formattedFeeComponents.value)
        hasher.combine(formattedFeeComponents.error != nil)
        hasher.combine(isSelected)
        hasher.combine(hasIssues)
    }

    static func == (lhs: FeeRowViewModel, rhs: FeeRowViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
