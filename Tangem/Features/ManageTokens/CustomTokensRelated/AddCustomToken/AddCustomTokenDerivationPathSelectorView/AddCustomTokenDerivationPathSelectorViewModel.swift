//
//  AddCustomTokenDerivationPathSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemSdk
import BlockchainSdk

final class AddCustomTokenDerivationPathSelectorViewModel: ObservableObject {
    @Published var customDerivationModel: AddCustomTokenDerivationPathSelectorItemViewModel!
    @Published var blockchainDerivationModels: [AddCustomTokenDerivationPathSelectorItemViewModel] = []

    weak var coordinator: AddCustomTokenDerivationPathSelectorRoutable?

    private var allItemViewModels: [AddCustomTokenDerivationPathSelectorItemViewModel] {
        var result: [AddCustomTokenDerivationPathSelectorItemViewModel] = []
        if let customDerivationModel {
            result.append(customDerivationModel)
        }
        result.append(contentsOf: blockchainDerivationModels)
        return result
    }

    private let context: ManageTokensContext
    private let blockchain: Blockchain

    init(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption],
        context: ManageTokensContext,
        blockchain: Blockchain
    ) {
        self.context = context
        self.blockchain = blockchain
        let customDerivationOption: AddCustomTokenDerivationOption
        if case .custom = selectedDerivationOption {
            customDerivationOption = selectedDerivationOption
        } else {
            customDerivationOption = .custom(derivationPath: nil)
        }
        customDerivationModel = makeModel(option: customDerivationOption, selectedDerivationOption: selectedDerivationOption)

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
            self?.didTapOption($0)
        }
    }

    private func didTapOption(_ derivationOption: AddCustomTokenDerivationOption) {
        guard case .custom(let derivationPath) = derivationOption else {
            selectOption(derivationOption)
            return
        }

        let currentCustomDerivationPath = derivationPath?.rawPath ?? ""

        coordinator?.openDerivationPathWriter(
            currentDerivationPath: currentCustomDerivationPath,
            context: context,
            blockchain: blockchain,
            output: self
        )
    }

    private func selectOption(_ derivationOption: AddCustomTokenDerivationOption) {
        for model in allItemViewModels {
            model.isSelected = (model.id == derivationOption.id)
        }

        coordinator?.didSelectOption(derivationOption)
    }

    private func setAndSelectDerivation(enteredDerivationPath: String) {
        customDerivationModel.setCustomDerivationPath(enteredDerivationPath)
        selectOption(customDerivationModel.option)
    }
}

// MARK: - AddCustomTokenDerivationPathWriterOutput

extension AddCustomTokenDerivationPathSelectorViewModel: AddCustomTokenDerivationPathWriterOutput {
    func didEnterCustomDerivation(_ derivationPath: String) {
        setAndSelectDerivation(enteredDerivationPath: derivationPath)
    }
}
