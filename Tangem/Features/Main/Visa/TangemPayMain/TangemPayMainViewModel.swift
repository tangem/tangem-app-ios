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

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Published private(set) var tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel?
    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false

    private let tangemPayAccount: TangemPayAccount
    private let transactionHistoryService: TangemPayTransactionHistoryService
    private var tangemPayCardDetailsViewModelFactory: TangemPayCardDetailsViewModelFactory?

    private weak var coordinator: TangemPayRoutable?

    private var bag = Set<AnyCancellable>()

    init(tangemPayAccount: TangemPayAccount, coordinator: TangemPayRoutable) {
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        mainHeaderViewModel = MainHeaderViewModel(
            isUserWalletLocked: false,
            supplementInfoProvider: tangemPayAccount,
            subtitleProvider: tangemPayAccount,
            balanceProvider: tangemPayAccount,
            updatePublisher: .empty
        )

        transactionHistoryService = TangemPayTransactionHistoryService(apiService: tangemPayAccount.customerInfoManagementService)

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
        let viewModel: any FloatingSheetContentViewModel
        if let depositAddress = tangemPayAccount.depositAddress {
            let receiveViewModel = ReceiveMainViewModel(
                options: .init(
                    tokenItem: TangemPayUtilities.usdcTokenItem,
                    flow: .crypto,
                    addressTypesProvider: TangemPayReceiveAddressTypesProvider(address: depositAddress, colorScheme: .whiteBlack),
                    isYieldModuleActive: false
                )
            )
            receiveViewModel.start()

            viewModel = receiveViewModel
        } else {
            viewModel = TangemPayNoDepositAddressSheetViewModel(
                close: { [floatingSheetPresenter] in
                    runTask {
                        await floatingSheetPresenter.removeActiveSheet()
                    }
                }
            )
        }

        runTask { [floatingSheetPresenter] in
            await floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func onAppear() {
        tangemPayAccount.loadBalance()
    }

    func onDisappear() {
        tangemPayAccount.loadCustomerInfo()
    }

    func openAddToApplePayGuide() {
        guard let newCardDetailsViewModel = tangemPayCardDetailsViewModelFactory?.makeViewModel() else { return }
        coordinator?.openAddToApplePayGuide(viewModel: newCardDetailsViewModel)
    }
}

private extension TangemPayMainViewModel {
    func bind() {
        tangemPayAccount.tangemPayCardDetailsPublisher
            .map { [weak self] cardDetails -> TangemPayCardDetailsViewModelFactory? in
                guard let (card, _) = cardDetails, let self else {
                    return nil
                }
                return TangemPayCardDetailsViewModelFactory(
                    lastFourDigits: card.cardNumberEnd,
                    customerInfoManagementService: tangemPayAccount.customerInfoManagementService
                )
            }
            .receiveOnMain()
            .handleEvents(
                receiveOutput: { [weak self] factory in
                    self?.tangemPayCardDetailsViewModel = factory?.makeViewModel()
                }
            )
            .assign(to: \.tangemPayCardDetailsViewModelFactory, on: self, ownership: .weak)
            .store(in: &bag)

        transactionHistoryService
            .tangemPayTransactionHistoryState
            .receiveOnMain()
            .assign(to: \.tangemPayTransactionHistoryState, on: self, ownership: .weak)
            .store(in: &bag)

        AppSettings.shared
            .$tangemPayHasDismissedAddToApplePayGuide
            .filter { $0 }
            .sink { [weak self] _ in
                self?.shouldDisplayAddToApplePayGuide = false
            }
            .store(in: &bag)
    }
}
