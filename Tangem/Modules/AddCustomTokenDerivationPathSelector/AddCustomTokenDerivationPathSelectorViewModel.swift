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

    private unowned let coordinator: AddCustomTokenDerivationPathSelectorRoutable

    init(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption],
        coordinator: AddCustomTokenDerivationPathSelectorRoutable
    ) {
        self.selectedDerivationOption = selectedDerivationOption
        customDerivationOption = .custom(derivationPath: nil)

        var derivationOptions: [AddCustomTokenDerivationOption] = []
        derivationOptions.append(.default(derivationPath: defaultDerivationPath))
        derivationOptions.append(contentsOf: blockchainDerivationOptions.sorted(by: { $0.name < $1.name }))
        self.derivationOptions = derivationOptions

        self.coordinator = coordinator

        customDerivationModel = AddCustomTokenDerivationPathSelectorItemViewModel(option: .custom(derivationPath: nil), isSelected: false) {
            [weak self] in
            self?.didTapOption()
        }
        
        let blockchainOptions: [AddCustomTokenDerivationOption] = [.default(derivationPath: defaultDerivationPath)]
        +
        blockchainDerivationOptions.sorted(by: \.name)
        
        self.blockchainDerivationModels = blockchainOptions.map { option in
            AddCustomTokenDerivationPathSelectorItemViewModel(option: option, isSelected: false) { [weak self] in
                self?.didTapOption()
            }
        }
    }

    func didTapOption() {
        print("TAP")
    }
}
