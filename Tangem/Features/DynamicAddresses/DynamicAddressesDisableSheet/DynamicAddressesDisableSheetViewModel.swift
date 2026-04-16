//
//  DynamicAddressesDisableSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemUI
import TangemUIUtils
import TangemLocalization

protocol DynamicAddressesDisableSheetRoutable: AnyObject {
    func closeDynamicAddressesDisableSheet()
}

final class DynamicAddressesDisableSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let icon: BottomSheetErrorContentView.Icon = .attention

    @Published private(set) var actionType: ActionType?
    @Published private(set) var isLoading: Bool = false

    private let dynamicAddressesManager: DynamicAddressesManager
    private let compoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory
    private weak var coordinator: (any DynamicAddressesDisableSheetRoutable)?

    init(
        dynamicAddressesManager: DynamicAddressesManager,
        compoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory,
        coordinator: any DynamicAddressesDisableSheetRoutable
    ) {
        self.dynamicAddressesManager = dynamicAddressesManager
        self.compoundFlowBaseDependenciesFactory = compoundFlowBaseDependenciesFactory
        self.coordinator = coordinator

        setupView()
    }

    func dismiss() {
        coordinator?.closeDynamicAddressesDisableSheet()
    }

    private func setupView() {
        switch dynamicAddressesManager.disablingRequirements {
        case .compoundTransaction(let amount, let destination):
            let dependencies = compoundFlowBaseDependenciesFactory.makeDependencies(
                amount: amount,
                destination: destination
            )

            let compoundViewModel = DynamicAddressesCompoundTransactionViewModel(
                transferModel: dependencies.transferModel,
                notificationManager: dependencies.notificationManager,
                dynamicAddressesManager: dynamicAddressesManager,
                onFinish: { [weak self] in
                    self?.close(isSuccess: true)
                }
            )

            actionType = .compoundTransactionDisable(compoundViewModel)

        case .none:
            actionType = .disable { [weak self] in
                self?.confirm()
            }
        }
    }

    private func confirm() {
        isLoading = true
        defer { isLoading = false }

        do {
            try dynamicAddressesManager.disableDynamicAddresses()
            close(isSuccess: true)
        } catch {
            alertPresenter.present(alert: error.alertBinder)
        }
    }

    private func close(isSuccess: Bool) {
        coordinator?.closeDynamicAddressesDisableSheet()

        if isSuccess {
            showSuccessToast()
        }
    }

    private func showSuccessToast() {
        Toast(view: SuccessToast(text: Localization.dynamicAddressesDisabledPopupTitle))
            .present(layout: .top(), type: .temporary())
    }
}

extension DynamicAddressesDisableSheetViewModel {
    enum ActionType {
        case disable(action: () -> Void)
        case compoundTransactionDisable(DynamicAddressesCompoundTransactionViewModel)
    }
}
