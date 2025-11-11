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
    let tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel
    let mainHeaderViewModel: MainHeaderViewModel
    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }
        _ = await (
            tangemPayAccount.loadBalance().value,
            transactionHistoryService.reloadHistory().value
        )
    }

    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayMainRoutable?

    private let transactionHistoryService: TangemPayTransactionHistoryService

    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        cardNumberEnd: String,
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

        tangemPayCardDetailsViewModel = TangemPayCardDetailsViewModel(
            lastFourDigits: cardNumberEnd,
            customerInfoManagementService: tangemPayAccount.customerInfoManagementService
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
        coordinator?.openAddToApplePayGuide(viewModel: tangemPayCardDetailsViewModel)
    }

    func showFreezePopup() {
        coordinator?.openTangemPayFreezeSheet { [weak self] in
            self?.freeze()
        }
    }

    func unfreeze() {
        guard let cardId = tangemPayAccount.cardId else {
            showFreezeUnfreezeErrorToast(freeze: false)
            return
        }

        freezingState = .unfreezingInProgress
        tangemPayCardDetailsViewModel.state = .loading(isFrozen: tangemPayCardDetailsViewModel.state.isFrozen)

        Task { @MainActor in
            do {
                try await tangemPayAccount.unfreeze(cardId: cardId)
            } catch {
                freezingState = .frozen
                showFreezeUnfreezeErrorToast(freeze: false)
            }
        }
    }

    private func freeze() {
        guard let cardId = tangemPayAccount.cardId else {
            showFreezeUnfreezeErrorToast(freeze: true)
            return
        }

        freezingState = .freezingInProgress
        tangemPayCardDetailsViewModel.state = .loading(isFrozen: tangemPayCardDetailsViewModel.state.isFrozen)

        Task { @MainActor in
            do {
                try await tangemPayAccount.freeze(cardId: cardId)
            } catch {
                freezingState = .normal
                showFreezeUnfreezeErrorToast(freeze: true)
            }
        }
    }

    private func showFreezeUnfreezeErrorToast(freeze: Bool) {
        let actionString = freeze ? "freeze" : "unfreeze"
        Toast(view: WarningToast(text: "Failed to \(actionString) the card. Try again later."))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }
}

private extension TangemPayMainViewModel {
    func bind() {
        transactionHistoryService
            .tangemPayTransactionHistoryState
            .receiveOnMain()
            .assign(to: &$tangemPayTransactionHistoryState)

        AppSettings.shared.$tangemPayHasDismissedAddToApplePayGuide
            .map { !$0 }
            .assign(to: &$shouldDisplayAddToApplePayGuide)

        tangemPayAccount.tangemPayStatusPublisher
            .map { $0 == .blocked ? .frozen : .normal }
            .receiveOnMain()
            .assign(to: \.freezingState, on: self, ownership: .weak)
            .store(in: &bag)

        $freezingState
            .map(\.cardDetailsState)
            .receiveOnMain()
            .assign(to: \.state, on: tangemPayCardDetailsViewModel, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - TangemPayFreezingState+TangemPayCardDetailsState

private extension TangemPayFreezingState {
    var cardDetailsState: TangemPayCardDetailsState {
        switch self {
        case .normal:
            .hidden(isFrozen: false)
        case .freezingInProgress:
            .loading(isFrozen: false)
        case .frozen:
            .hidden(isFrozen: true)
        case .unfreezingInProgress:
            .loading(isFrozen: true)
        }
    }
}
