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

    private weak var coordinator: (any DynamicAddressesDisableSheetRoutable)?

    init(coordinator: any DynamicAddressesDisableSheetRoutable) {
        self.coordinator = coordinator

        setupView()
    }

    func dismiss() {
        coordinator?.closeDynamicAddressesDisableSheet()
    }

    private func setupView() {
        actionType = .disable { [weak self] in
            self?.confirm()
        }
    }

    private func confirm() {
        isLoading = true
        defer { isLoading = false }

        // [REDACTED_TODO_COMMENT]
        close(isSuccess: true)
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
