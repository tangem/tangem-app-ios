//
//  BlockchainAccountInitializationViewModel.swift
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

final class BlockchainAccountInitializationViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    @Published var feeRowViewModel: DefaultRowViewModel
    @Published var isLoading = false

    let tokenIconInfo: TokenIconInfo

    private let feeFormatter = CommonFeeFormatter(
        balanceFormatter: .init(),
        balanceConverter: .init()
    )

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let fee: Fee
    private let feeTokenItem: TokenItem

    private let onStartInitialization: () -> Void
    private let onInitialized: () -> Void

    private let accountInitializationService: BlockchainAccountInitializationService
    private let transactionDispatcher: TransactionDispatcher

    init(
        accountInitializationService: BlockchainAccountInitializationService,
        transactionDispatcher: TransactionDispatcher,
        tokenItem: TokenItem,
        fee: Fee,
        feeTokenItem: TokenItem,
        tokenIconInfo: TokenIconInfo,
        onStartInitialization: @escaping () -> Void,
        onInitialized: @escaping () -> Void
    ) {
        self.accountInitializationService = accountInitializationService
        self.transactionDispatcher = transactionDispatcher

        self.tokenItem = tokenItem
        self.fee = fee
        self.feeTokenItem = feeTokenItem
        self.tokenIconInfo = tokenIconInfo

        self.onStartInitialization = onStartInitialization
        self.onInitialized = onInitialized

        feeRowViewModel = DefaultRowViewModel(title: Localization.commonNetworkFeeTitle, detailsType: .none)

        updateView(state: .success(fee))
    }

    func onAppear() {
        Analytics.log(event: .stakingUninitializedAddressScreen, params: analyticsParams)
    }

    func initializeAccount() {
        Analytics.log(event: .stakingButtonActivate, params: analyticsParams)

        isLoading = true
        Task { @MainActor in
            do {
                let transaction = accountInitializationService.initializationTransaction(fee: fee)
                _ = try await transactionDispatcher.send(transaction: .transfer(transaction))
                onStartInitialization()
                try await Task.sleep(for: .seconds(Constants.startPollingInterval)) // activation takes some time, doesn't make sense to start tracking earlier
                try await trackInitializationStatus()
                onInitialized()
                dismiss()
            } catch TransactionDispatcherResult.Error.userCancelled {
                updateView(state: .success(fee))
            } catch {
                updateView(state: .failure(error))
            }
        }
    }

    @MainActor
    func dismiss() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

private extension BlockchainAccountInitializationViewModel {
    func updateView(state: LoadingResult<Fee, any Error>) {
        switch state {
        case .success(let fee):
            updateFeeAmount(fee: fee)
            isLoading = false
        case .loading:
            feeRowViewModel.update(detailsType: .loader)
            isLoading = true
        case .failure(let error):
            isLoading = false
            alertPresenter.present(
                alert: AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            )
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

            try await Task.sleep(for: .seconds(Constants.pollingInterval))
        }

        throw StakingModelError.accountIsNotInitialized
    }

    var analyticsParams: [Analytics.ParameterKey: String] {
        [
            .blockchain: tokenItem.blockchain.displayName,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
        ]
    }
}

extension BlockchainAccountInitializationViewModel {
    enum Constants {
        static let startPollingInterval: TimeInterval = 5
        static let pollingTimeout: TimeInterval = 30
        static let pollingInterval: TimeInterval = 2
    }
}
