//
//  AddCustomTokenDerivationPathSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class AddCustomTokenDerivationPathSelectorItemViewModel: ObservableObject {
    var id: String {
        option.id
    }

    var name: String {
        option.name
    }

    var derivationPath: String? {
        option.derivation
    }

    @Published var isSelected: Bool

    let didTapOption: () -> Void
    private var option: AddCustomTokenDerivationOption

    init(option: AddCustomTokenDerivationOption, isSelected: Bool, didTapOption: @escaping () -> Void) {
        self.isSelected = isSelected
        self.option = option
        self.didTapOption = didTapOption
    }
}
