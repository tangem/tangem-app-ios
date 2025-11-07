//
//  TangemPayMainViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import TangemVisa
import TangemFoundation
import PassKit

final class TangemPayMainViewModel: ObservableObject {
    let mainHeaderViewModel: MainHeaderViewModel
    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }
        _ = await (
            tangemPayAccount.loadBalance().value,
            transactionHistoryService.reloadHistory().value
        )
    }

    @Published private(set) var tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel?
    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayMainRoutable?

    private let transactionHistoryService: TangemPayTransactionHistoryService
    private var tangemPayCardDetailsViewModelFactory: TangemPayCardDetailsViewModelFactory?

    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayMainRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        mainHeaderViewModel = MainHeaderViewModel(
            isUserWalletLocked: false,
            supplementInfoProvider: tangemPayAccount,
            subtitleProvider: tangemPayAccount,
            balanceProvider: tangemPayAccount,
            updatePublisher: .empty
        )

        transactionHistoryService = TangemPayTransactionHistoryService(
            apiService: tangemPayAccount.customerInfoManagementService
        )

        bind()
        reloadHistory()
        fetchAccountStatus()
    }

    func reloadHistory() {
        transactionHistoryService.reloadHistory()
    }

    func fetchAccountStatus() {
        Task { @MainActor [tangemPayAccount, weak self] in
            let status = try? await tangemPayAccount.getTangemPayStatus()

            self?.shouldDisplayAddToApplePayGuide = status == .active
                && PKPaymentAuthorizationViewController.canMakePayments()
                && !AppSettings.shared.tangemPayHasDismissedAddToApplePayGuide
        }
    }

    func fetchNextTransactionHistoryPage() -> FetchMore? {
        transactionHistoryService.fetchNextTransactionHistoryPage()
    }

    func addFunds() {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            coordinator?.openTangemPayNoDepositAddressSheet()
            return
        }

        let tangemPayDestinationWalletWrapper = TangemPayDestinationWalletWrapper(
            tokenItem: TangemPayUtilities.usdcTokenItem,
            address: depositAddress,
            balancePublisher: tangemPayAccount.balancePublisher
        )

        coordinator?.openTangemPayAddFundsSheet(
            input: .init(
                userWalletInfo: userWalletInfo,
                address: depositAddress,
                tangemPayDestinationWalletWrapper: tangemPayDestinationWalletWrapper
            )
        )
    }

    func onAppear() {
        tangemPayAccount.loadBalance()
    }

    func onDisappear() {
        tangemPayAccount.loadCustomerInfo()
    }

    func openAddToApplePayGuide() {
        guard let newCardDetailsViewModel = tangemPayCardDetailsViewModel else {
            return
        }

        coordinator?.openAddToApplePayGuide(viewModel: newCardDetailsViewModel)
    }
}

private extension TangemPayMainViewModel {
    func bind() {
        tangemPayAccount.tangemPayCardDetailsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, cardDetails in
                guard let (card, _) = cardDetails else {
                    return nil
                }

                return TangemPayCardDetailsViewModel(
                    lastFourDigits: card.cardNumberEnd,
                    customerInfoManagementService: viewModel.tangemPayAccount.customerInfoManagementService
                )
            }
            .receiveOnMain()
            .assign(to: &$tangemPayCardDetailsViewModel)

        transactionHistoryService
            .tangemPayTransactionHistoryState
            .receiveOnMain()
            .assign(to: &$tangemPayTransactionHistoryState)

        AppSettings.shared.$tangemPayHasDismissedAddToApplePayGuide
            .map { !$0 }
            .assign(to: &$shouldDisplayAddToApplePayGuide)
    }
}
