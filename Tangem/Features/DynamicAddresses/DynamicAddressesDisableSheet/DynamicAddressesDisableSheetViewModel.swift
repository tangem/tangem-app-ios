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

    private let walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider
    private let compoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory
    private let analyticsLogger: DynamicAddressesAnalyticsLogger
    private weak var coordinator: (any DynamicAddressesDisableSheetRoutable)?

    private var disablingTask: Task<Void, Never>?

    init(
        walletModelDynamicAddressesProvider: WalletModelDynamicAddressesProvider,
        compoundFlowBaseDependenciesFactory: DynamicAddressesCompoundFlowBaseDependenciesFactory,
        analyticsLogger: DynamicAddressesAnalyticsLogger,
        coordinator: any DynamicAddressesDisableSheetRoutable
    ) {
        self.walletModelDynamicAddressesProvider = walletModelDynamicAddressesProvider
        self.compoundFlowBaseDependenciesFactory = compoundFlowBaseDependenciesFactory
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator

        setupView()
    }

    func dismiss() {
        disablingTask?.cancel()
        coordinator?.closeDynamicAddressesDisableSheet()
    }

    private func setupView() {
        switch walletModelDynamicAddressesProvider.dynamicAddressesDisablingRequirements {
        case .compoundTransaction(let amount, let destination):
            let dependencies = compoundFlowBaseDependenciesFactory.makeDependencies(
                amount: amount,
                destination: destination
            )

            let compoundViewModel = DynamicAddressesCompoundTransactionViewModel(
                transferModel: dependencies.transferModel,
                notificationManager: dependencies.notificationManager,
                walletModelDynamicAddressesProvider: walletModelDynamicAddressesProvider,
                analyticsLogger: analyticsLogger,
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
        analyticsLogger.logButtonDisableDynamicAddresses()

        isLoading = true
        disablingTask?.cancel()
        disablingTask = Task { [weak self] in
            await self?.disableDynamicAddresses()
        }
    }

    private func disableDynamicAddresses() async {
        do {
            try await walletModelDynamicAddressesProvider.disableDynamicAddresses()
            analyticsLogger.logDynamicAddressesDisabled()

            await MainActor.run {
                self.isLoading = false
                self.close(isSuccess: true)
            }
        } catch is CancellationError {
            // Do nothing
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.alertPresenter.present(alert: error.alertBinder)
            }
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
