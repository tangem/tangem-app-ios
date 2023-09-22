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

    @Published var customDerivationModel: AddCustomTokenDerivationPathSelectorItemViewModel!
    @Published var blockchainDerivationModels: [AddCustomTokenDerivationPathSelectorItemViewModel] = []

    // MARK: - Dependencies

    weak var delegate: AddCustomTokenDerivationPathSelectorDelegate?

    private var allItemViewModels: [AddCustomTokenDerivationPathSelectorItemViewModel] {
        var result: [AddCustomTokenDerivationPathSelectorItemViewModel] = []
        if let customDerivationModel {
            result.append(customDerivationModel)
        }
        result.append(contentsOf: blockchainDerivationModels)
        return result
    }

    init(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption]
    ) {
        customDerivationModel = makeModel(option: .custom(derivationPath: nil), selectedDerivationOption: selectedDerivationOption)

        let blockchainOptions = [.default(derivationPath: defaultDerivationPath)] + blockchainDerivationOptions.sorted(by: \.name)
        blockchainDerivationModels = blockchainOptions.map { option in
            makeModel(option: option, selectedDerivationOption: selectedDerivationOption)
        }
    }

    func makeModel(option: AddCustomTokenDerivationOption, selectedDerivationOption: AddCustomTokenDerivationOption) -> AddCustomTokenDerivationPathSelectorItemViewModel {
        AddCustomTokenDerivationPathSelectorItemViewModel(
            option: option,
            isSelected: option.id == selectedDerivationOption.id
        ) { [weak self] in
            self?.didTapOption(option)
        }
    }

    func didTapOption(_ derivationOption: AddCustomTokenDerivationOption) {
        selectOption(derivationOption)
    }

    private func selectOption(_ derivationOption: AddCustomTokenDerivationOption) {
        for model in allItemViewModels {
            model.isSelected = (model.id == derivationOption.id)
        }

        delegate?.didSelectOption(derivationOption)
    }
}
