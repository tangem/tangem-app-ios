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

    private let customDerivationPathValidator = AlertFieldValidator { input in
        let derivationPath = try? DerivationPath(rawPath: input)
        return derivationPath != nil
    }

    init(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption]
    ) {
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
            self?.didTapOption(with: option.id)
        }
    }

    private func didTapOption(with id: String) {
        guard let derivationOption = allItemViewModels.first(where: { $0.id == id })?.option else { return }

        guard case .custom(let derivationPath) = derivationOption else {
            selectOption(derivationOption)
            return
        }

        let currentCustomDerivationPath = derivationPath?.rawPath ?? ""

        let alert = AlertBuilder.makeAlertControllerWithTextField(
            title: Localization.customTokenCustomDerivationTitle,
            fieldPlaceholder: Localization.customTokenCustomDerivationPlaceholder,
            fieldText: currentCustomDerivationPath,
            autoCapitalize: false,
            useSpellCheck: false,
            fieldValidator: customDerivationPathValidator
        ) { [weak self] enteredDerivationPath in
            guard let self else { return }

            customDerivationModel.setCustomDerivationPath(enteredDerivationPath)
            selectOption(customDerivationModel.option)
        }

        AppPresenter.shared.show(alert)
    }

    private func selectOption(_ derivationOption: AddCustomTokenDerivationOption) {
        for model in allItemViewModels {
            model.isSelected = (model.id == derivationOption.id)
        }

        delegate?.didSelectOption(derivationOption)
    }
}
