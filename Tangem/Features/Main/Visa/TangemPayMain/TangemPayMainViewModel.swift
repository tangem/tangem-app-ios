//
//  TangemPayMainViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import PassKit
import TangemUI
import TangemVisa
import TangemUIUtils
import TangemFoundation
import TangemLocalization

final class TangemPayMainViewModel: ObservableObject {
    let tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel
    let mainHeaderViewModel: MainHeaderViewModel
    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }

        async let balanceUpdate: Void = tangemPayAccount.loadBalance().value
        async let transactionsUpdate: Void = transactionHistoryService.reloadHistory().value

        _ = await (balanceUpdate, transactionsUpdate)
    }

    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    @Published private(set) var isWithdrawButtonLoading: Bool = false
    @Published var alert: AlertBinder?

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayMainRoutable?

    private let transactionHistoryService: TangemPayTransactionHistoryService
    private let cardDetailsRepository: TangemPayCardDetailsRepository

    private var nextViewOpeningTask: Task<Void, Error>?
    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayMainRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        cardDetailsRepository = .init(
            lastFourDigits: tangemPayAccount.cardNumberEnd ?? "",
            customerService: tangemPayAccount.customerInfoManagementService
        )

        mainHeaderViewModel = MainHeaderViewModel(
            isUserWalletLocked: false,
            supplementInfoProvider: tangemPayAccount,
            subtitleProvider: tangemPayAccount.tangemPayMainHeaderSubtitleProvider,
            balanceProvider: tangemPayAccount.tangemPayMainHeaderBalanceProvider,
            updatePublisher: .empty
        )

        transactionHistoryService = TangemPayTransactionHistoryService(
            apiService: tangemPayAccount.customerInfoManagementService
        )

        tangemPayCardDetailsViewModel = TangemPayCardDetailsViewModel(
            mode: .interactive,
            repository: cardDetailsRepository
        )

        bind()
        reloadHistory()
    }

    func reloadHistory() {
        transactionHistoryService.reloadHistory()
    }

    func fetchNextTransactionHistoryPage() -> FetchMore? {
        transactionHistoryService.fetchNextTransactionHistoryPage()
    }

    func addFunds() {
        Analytics.log(.visaMainScreenButtonAddFunds)

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = Task { @MainActor in
            guard let depositAddress = tangemPayAccount.depositAddress,
                  let tangemPayWalletWrapper = makeExpressInteractorTangemPayWalletWrapper() else {
                coordinator?.openTangemPayNoDepositAddressSheet()
                return
            }

            coordinator?.openTangemPayAddFundsSheet(
                input: .init(
                    userWalletInfo: userWalletInfo,
                    address: depositAddress,
                    tangemPayWalletWrapper: tangemPayWalletWrapper
                )
            )
        }
    }

    func withdraw() {
        guard let tangemPayWalletWrapper = makeExpressInteractorTangemPayWalletWrapper() else {
            coordinator?.openTangemPayNoDepositAddressSheet()
            return
        }

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = runWithDelayedLoading(onLongRunning: { @MainActor [weak self] in
            self?.isWithdrawButtonLoading = true
        }, onCancel: { [weak self] in
            self?.isWithdrawButtonLoading = false
        }) { @MainActor [weak self] in
            self?.isWithdrawButtonLoading = false

            do {
                try await self?.openWithdraw(tangemPayWalletWrapper: tangemPayWalletWrapper)
            } catch is CancellationError {
                // Do nothing
            } catch {
                self?.alert = error.alertBinder
            }
        }
    }

    func onAppear() {
        Analytics.log(.visaMainScreenMainScreenOpened)

        tangemPayAccount.loadBalance()
    }

    func onDisappear() {
        tangemPayAccount.loadCustomerInfo()
    }

    func openAddToApplePayGuide() {
        coordinator?.openAddToApplePayGuide(
            viewModel: .init(mode: .detailedOnly, repository: cardDetailsRepository)
        )
    }

    func dismissAddToApplePayGuideBanner() {
        AppSettings.shared.tangemPayShowAddToApplePayGuide = false
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

    func setPin() {
        coordinator?.openTangemPayPin(tangemPayAccount: tangemPayAccount)
    }

    func termsAndLimits() {
        coordinator?.openTermsAndLimits()
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
        let message = freeze
            ? Localization.tangemPayFreezeCardFailed
            : Localization.tangemPayUnfreezeCardFailed

        Toast(view: WarningToast(text: message))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }

    func openTransactionDetails(id: String) {
        guard let transaction = transactionHistoryService.getTransaction(id: id) else {
            assertionFailure("Transaction not found")
            return
        }

        coordinator?.openTangemPayTransactionDetailsSheet(transaction: transaction)
    }
}

// MARK: - Private

private extension TangemPayMainViewModel {
    func bind() {
        transactionHistoryService
            .tangemPayTransactionHistoryState
            .receiveOnMain()
            .assign(to: &$tangemPayTransactionHistoryState)

        Publishers.CombineLatest(
            AppSettings.shared.$tangemPayShowAddToApplePayGuide,
            tangemPayAccount.tangemPayStatusPublisher
        )
        .map { tangemPayShowAddToApplePayGuide, status in
            PKPaymentAuthorizationViewController.canMakePayments()
                && status == .active
                && tangemPayShowAddToApplePayGuide
        }
        .receiveOnMain()
        .assign(to: \.shouldDisplayAddToApplePayGuide, on: self, ownership: .weak)
        .store(in: &bag)

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

    func makeExpressInteractorTangemPayWalletWrapper() -> ExpressInteractorTangemPayWalletWrapper? {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            return nil
        }

        let tangemPayWalletWrapper = ExpressInteractorTangemPayWalletWrapper(
            tokenItem: TangemPayUtilities.usdcTokenItem,
            feeTokenItem: TangemPayUtilities.usdcTokenItem,
            defaultAddressString: depositAddress,
            availableBalanceProvider: tangemPayAccount.tangemPayTokenBalanceProvider,
            cexTransactionProcessor: tangemPayAccount.tangemPayExpressCEXTransactionProcessor,
            transactionValidator: TangemPayExpressTransactionValidator(
                availableBalanceProvider: tangemPayAccount.tangemPayTokenBalanceProvider
            )
        )

        return tangemPayWalletWrapper
    }

    @MainActor
    func openWithdraw(tangemPayWalletWrapper: ExpressInteractorTangemPayWalletWrapper) async throws {
        let hasActiveWithdrawOrder = try await tangemPayAccount.withdrawTransactionService.hasActiveWithdrawOrder()
        try Task.checkCancellation()

        if hasActiveWithdrawOrder {
            coordinator?.openTangemWithdrawInProgressSheet()
            return
        }

        coordinator?.openTangemPayWithdraw(input: ExpressDependenciesInput(
            userWalletInfo: userWalletInfo,
            source: tangemPayWalletWrapper,
            destination: .loadingAndSet
        ))
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
