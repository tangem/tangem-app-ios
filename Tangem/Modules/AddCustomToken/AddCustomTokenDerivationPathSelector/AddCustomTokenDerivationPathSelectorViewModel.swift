//
//  AddCustomTokenDerivationPathSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSdk

final class AddCustomTokenDerivationPathSelectorViewModel: ObservableObject {
    // MARK: - ViewState

    let selectedDerivationOption: AddCustomTokenDerivationOption

    private(set) var customDerivationModel: AddCustomTokenDerivationPathSelectorItemViewModel!
    private(set) var blockchainDerivationModels: [AddCustomTokenDerivationPathSelectorItemViewModel] = []

    let customDerivationOption: AddCustomTokenDerivationOption
    let derivationOptions: [AddCustomTokenDerivationOption]

    // MARK: - Dependencies

    weak var delegate: AddCustomTokenDerivationPathSelectorDelegate?

    init(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption]
    ) {
        self.selectedDerivationOption = selectedDerivationOption
        customDerivationOption = .custom(derivationPath: nil)

        var derivationOptions: [AddCustomTokenDerivationOption] = []
        derivationOptions.append(.default(derivationPath: defaultDerivationPath))
        derivationOptions.append(contentsOf: blockchainDerivationOptions.sorted(by: { $0.name < $1.name }))
        self.derivationOptions = derivationOptions

        customDerivationModel = AddCustomTokenDerivationPathSelectorItemViewModel(option: .custom(derivationPath: nil), isSelected: false) {
            [weak self] in
            self?.didTapOption()
        }

        let blockchainOptions: [AddCustomTokenDerivationOption] = [.default(derivationPath: defaultDerivationPath)]
            +
            blockchainDerivationOptions.sorted(by: \.name)

        blockchainDerivationModels = blockchainOptions.map { option in
            AddCustomTokenDerivationPathSelectorItemViewModel(option: option, isSelected: false) { [weak self] in
                self?.didTapOption()
            }
        }
    }

    func didTapOption() {
        print("TAP")
    }
}
