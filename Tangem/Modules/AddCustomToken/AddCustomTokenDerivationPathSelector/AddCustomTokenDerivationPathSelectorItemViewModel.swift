//
//  AddCustomTokenDerivationPathSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AddCustomTokenDerivationPathSelectorItemViewModel: ObservableObject {
    var id: String {
        option.id
    }

    var name: String {
        option.name
    }

    var derivationPath: String? {
        option.derivationDath
    }

    @Published var isSelected: Bool

    private let didTapOption: (AddCustomTokenDerivationOption) -> Void
    private(set) var option: AddCustomTokenDerivationOption

    init(option: AddCustomTokenDerivationOption, isSelected: Bool, didTapOption: @escaping (AddCustomTokenDerivationOption) -> Void) {
        self.isSelected = isSelected
        self.option = option
        self.didTapOption = didTapOption
    }

    func setCustomDerivationPath(_ enteredText: String) {
        do {
            let derivationPath = try DerivationPath(rawPath: enteredText)
            option = .custom(derivationPath: derivationPath)
            objectWillChange.send()
        } catch {
            AppLog.shared.error(error)
            assertionFailure("You should validate entered derivation path")
        }
    }

    func didTap() {
        didTapOption(option)
    }
}
