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
import TangemUIUtils

final class AddCustomTokenDerivationPathSelectorViewModel: ObservableObject {
    @Published var customDerivationModel: AddCustomTokenDerivationPathSelectorItemViewModel!
    @Published var blockchainDerivationModels: [AddCustomTokenDerivationPathSelectorItemViewModel] = []
    @Published var alert: AlertBinder?

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

        let alert = AlertBuilder.makeAlertControllerWithTextField(
            title: Localization.customTokenCustomDerivationTitle,
            fieldPlaceholder: Localization.customTokenCustomDerivationPlaceholder,
            fieldText: currentCustomDerivationPath,
            autoCapitalize: false,
            useSpellCheck: false,
            fieldValidator: customDerivationPathValidator
        ) { [weak self] enteredDerivationPath in
            guard let self else { return }

            guard let derivationPath = try? DerivationPath(rawPath: enteredDerivationPath) else {
                return
            }

            let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: derivationPath))
            let destination = context.accountDestination(for: tokenItem)

            switch destination {
            case .currentAccount, .noAccount:
                setAndSelectDerivation(enteredDerivationPath: enteredDerivationPath)

            case .differentAccount(let accountName, _):
                showAccountMismatchAlert(accountName: accountName, enteredDerivationPath: enteredDerivationPath)
            }
        }

        AppPresenter.shared.show(alert)
    }

    private func selectOption(_ derivationOption: AddCustomTokenDerivationOption) {
        for model in allItemViewModels {
            model.isSelected = (model.id == derivationOption.id)
        }

        delegate?.didSelectOption(derivationOption)
    }

    private func showAccountMismatchAlert(accountName: String, enteredDerivationPath: String) {
        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.customTokenAnotherAccountDialogTitle,
            message: Localization.customTokenAnotherAccountDialogDescription(accountName),
            buttonText: Localization.commonGotIt,
            buttonAction: { [weak self] in
                self?.setAndSelectDerivation(enteredDerivationPath: enteredDerivationPath)
            }
        )
    }

    private func setAndSelectDerivation(enteredDerivationPath: String) {
        customDerivationModel.setCustomDerivationPath(enteredDerivationPath)
        selectOption(customDerivationModel.option)
    }
}
