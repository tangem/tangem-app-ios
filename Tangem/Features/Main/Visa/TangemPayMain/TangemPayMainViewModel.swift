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

    private let tangemPayAccount: TangemPayAccount
    private let transactionHistoryService: TangemPayTransactionHistoryService

    private var bag = Set<AnyCancellable>()

    init(tangemPayAccount: TangemPayAccount) {
        self.tangemPayAccount = tangemPayAccount

        mainHeaderViewModel = MainHeaderViewModel(
            isUserWalletLocked: false,
            supplementInfoProvider: tangemPayAccount,
            subtitleProvider: tangemPayAccount,
            balanceProvider: tangemPayAccount,
            updatePublisher: .empty
        )

        transactionHistoryService = TangemPayTransactionHistoryService(apiService: tangemPayAccount.customerInfoManagementService)

        tangemPayAccount.tangemPayCardDetailsPublisher
            .map { cardDetails -> TangemPayCardDetailsViewModel? in
                guard let (card, _) = cardDetails else {
                    return nil
                }
                return TangemPayCardDetailsViewModel(
                    lastFourDigits: card.cardNumberEnd,
                    customerInfoManagementService: tangemPayAccount.customerInfoManagementService
                )
            }
            .receiveOnMain()
            .assign(to: \.tangemPayCardDetailsViewModel, on: self, ownership: .weak)
            .store(in: &bag)

        transactionHistoryService
            .tangemPayTransactionHistoryState
            .receiveOnMain()
            .assign(to: \.tangemPayTransactionHistoryState, on: self, ownership: .weak)
            .store(in: &bag)

        reloadHistory()
    }

    func reloadHistory() {
        transactionHistoryService.reloadHistory()
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
}
