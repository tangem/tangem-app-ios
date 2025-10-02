//
//  AccountInitializationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import BlockchainSdk
import TangemUIUtils
import TangemFoundation
import TangemLocalization

final class AccountInitializationViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published var feeRowViewModel: DefaultRowViewModel
    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    let tokenIconInfo: TokenIconInfo

    private let feeFormatter = CommonFeeFormatter(
        balanceFormatter: .init(),
        balanceConverter: .init()
    )

    // MARK: - Dependencies

    private let fee: Fee
    private let feeTokenItem: TokenItem
    private let onInitialized: () -> Void

    private let accountInitializationService: StakingAccountInitializationService
    private let transactionDispatcher: TransactionDispatcher

    init(
        accountInitializationService: StakingAccountInitializationService,
        transactionDispatcher: TransactionDispatcher,
        fee: Fee,
        feeTokenItem: TokenItem,
        tokenIconInfo: TokenIconInfo,
        onInitialized: @escaping () -> Void
    ) {
        self.accountInitializationService = accountInitializationService
        self.transactionDispatcher = transactionDispatcher

        self.fee = fee
        self.feeTokenItem = feeTokenItem
        self.tokenIconInfo = tokenIconInfo

        self.onInitialized = onInitialized

        feeRowViewModel = DefaultRowViewModel(title: Localization.commonNetworkFeeTitle, detailsType: .none)

        updateView(state: .loaded(fee))
    }

    func initializeAccount() {
        isLoading = true
        Task { @MainActor in
            do {
                let transaction = accountInitializationService.initializationTransaction(fee: fee)
                let _ = try await transactionDispatcher.send(transaction: .transfer(transaction))
                try await Task.sleep(seconds: Constants.startPollingInterval) // this is necessary to avoid too fast dismiss animation
                try await trackInitializationStatus()
                onInitialized()
                dismiss()
            } catch TransactionDispatcherResult.Error.userCancelled {
                updateView(state: .loaded(fee))
            } catch {
                updateView(state: .failedToLoad(error: error))
            }
        }
    }

    @MainActor
    func dismiss() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

private extension AccountInitializationViewModel {
    func updateView(state: LoadingValue<Fee>) {
        switch state {
        case .loaded(let fee):
            updateFeeAmount(fee: fee)
            isLoading = false
            mainButtonIsDisabled = false
        case .loading:
            feeRowViewModel.update(detailsType: .loader)
            isLoading = true
            mainButtonIsDisabled = false
        case .failedToLoad(let error):
            errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func updateFeeAmount(fee: Fee) {
        let formatted = feeFormatter.format(fee: fee.amount.value, tokenItem: feeTokenItem)
        feeRowViewModel.update(detailsType: .text(formatted))
    }

    func trackInitializationStatus() async throws {
        let deadline = Date().addingTimeInterval(Constants.pollingTimeout)

        while Date() < deadline {
            try Task.checkCancellation()

            if try await accountInitializationService.isAccountInitialized() {
                return
            }

            try await Task.sleep(seconds: Constants.pollingInterval)
        }

        throw StakingModelError.accountIsNotInitialized
    }
}

extension AccountInitializationViewModel {
    enum Constants {
        static let startPollingInterval: TimeInterval = 2
        static let pollingTimeout: TimeInterval = 30
        static let pollingInterval: TimeInterval = 1
    }
}
