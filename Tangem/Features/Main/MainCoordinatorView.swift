//
//  MainCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemNFT
import TangemUI

struct MainCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MainCoordinator

    @State private var responderChainIntrospectionTrigger = UUID()

    @StateObject private var navigationAssertion = MainCoordinatorNavigationAssertion()

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    var body: some View {
        NavigationView {
            content
        }
        .navigationViewStyle(.stack)
    }

    private var content: some View {
        ZStack {
            if let mainViewModel = coordinator.mainViewModel {
                MainView(viewModel: mainViewModel)
                    .navigationLinks(links)
            }

            marketsTooltipView

            sheets
        }
        .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak coordinator] state in
            if !state.isCollapsed {
                coordinator?.hideMarketsTooltip()
            } else {
                // Workaround: If you open the markets screen, add a token, and return to the main page, the frames break and no longer align with the tap zone.
                // [REDACTED_INFO]
                // https://forums.developer.apple.com/forums/thread/724598
                if let vc = UIApplication.topViewController as? OverlayContentContainerViewController {
                    vc.resetContentFrame()
                }
            }
        }
        .onAppear {
            responderChainIntrospectionTrigger = UUID()
        }
        .introspectResponderChain(
            introspectedType: UINavigationController.self,
            updateOnChangeOf: responderChainIntrospectionTrigger
        ) { [weak navigationAssertion] navigationController in
            navigationController.safeSet(delegate: navigationAssertion)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.detailsCoordinator) {
                DetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                TokenDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.stakingDetailsCoordinator) {
                StakingDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.marketsTokenDetailsCoordinator) {
                MarketsTokenDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.referralCoordinator) {
                ReferralCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.nftCollectionsCoordinator) {
                NFTCollectionsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.tangemPayMainViewModel) {
                TangemPayMainView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .iOS16UIKitSheet(item: $coordinator.expressCoordinator) { coordinator in
                ExpressCoordinatorView(coordinator: coordinator)
                    .expressNavigationView()
            }
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.organizeTokensViewModel) { viewModel in
                NavigationBarHidingView(shouldWrapInNavigationView: true) {
                    OrganizeTokensView(viewModel: viewModel)
                        .navigationTitle(Localization.organizeTokensTitle)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(item: $coordinator.mobileUpgradeCoordinator) {
                MobileUpgradeCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.visaTransactionDetailsViewModel) {
                VisaTransactionDetailsView(viewModel: $0)
            }
            .sheet(item: $coordinator.actionButtonsBuyCoordinator) {
                ActionButtonsBuyCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.actionButtonsSellCoordinator) {
                ActionButtonsSellCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.actionButtonsSwapCoordinator) {
                ActionButtonsSwapCoordinatorView(coordinator: $0)
            }
            .floatingSheetContent(for: MobileFinishActivationNeededViewModel.self) {
                MobileFinishActivationNeededView(viewModel: $0)
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self) {
                ReceiveMainView(viewModel: $0)
            }
            .floatingSheetContent(for: YieldNoticeViewModel.self) {
                YieldNoticeView(viewModel: $0)
            }

        NavHolder()
            .bottomSheet(
                item: $coordinator.receiveBottomSheetViewModel,
                settings: .init(backgroundColor: Colors.Background.primary, contentScrollsHorizontally: true)
            ) {
                ReceiveBottomSheetView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.pushNotificationsViewModel,
                backgroundColor: Colors.Background.primary
            ) {
                PushNotificationsBottomSheetView(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.pendingExpressTxStatusBottomSheetViewModel,
                backgroundColor: Colors.Background.tertiary
            ) {
                PendingExpressTxStatusBottomSheetView(viewModel: $0)
            }

        NavHolder()
            .requestAppStoreReviewCompat($coordinator.isAppStoreReviewRequested)
    }

    /// Tooltip is placed on top of the other views
    private var marketsTooltipView: some View {
        BasicTooltipView(
            isShowBindingValue: $coordinator.isMarketsTooltipVisible,
            onHideAction: coordinator.hideMarketsTooltip,
            title: Localization.marketsTooltipTitle,
            message: Localization.marketsTooltipMessage
        )
    }
}

//import TangemFoundation
//
//final class TangemPayMainViewModel: ObservableObject {
//    let mainHeaderViewModel: MainHeaderViewModel
//    [REDACTED_USERNAME] private(set) var tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel?
//    [REDACTED_USERNAME] private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
//
//    private(set) lazy var refreshScrollViewStateObject: RefreshScrollViewStateObject = .init(
//        settings: .init(stopRefreshingDelay: 1, refreshTaskTimeout: 120), // 2 minutes
//        refreshable: { [weak self] in
//            guard let self else { return }
//            _ = await (tangemPayAccount.loadBalance().value, reloadHistory())
//        }
//    )
//
//    private let tangemPayAccount: TangemPayAccount
//    private let transactionHistoryService: VisaTransactionHistoryService
//
//    private var historyReloadTask: Task<Void, Never>?
//
//    init(tangemPayAccount: TangemPayAccount) {
//        self.tangemPayAccount = tangemPayAccount
//
//        mainHeaderViewModel = MainHeaderViewModel(
//            isUserWalletLocked: false,
//            supplementInfoProvider: tangemPayAccount,
//            subtitleProvider: tangemPayAccount,
//            balanceProvider: tangemPayAccount,
//            updatePublisher: .empty
//        )
//
//        transactionHistoryService = VisaTransactionHistoryService(apiService: tangemPayAccount.customerInfoManagementService)
//
//        tangemPayAccount.tangemPayCardDetailsPublisher
//            .map { cardDetails -> TangemPayCardDetailsViewModel? in
//                guard let (card, _) = cardDetails else {
//                    return nil
//                }
//                return TangemPayCardDetailsViewModel(
//                    lastFourDigits: card.cardNumberEnd,
//                    customerInfoManagementService: tangemPayAccount.customerInfoManagementService
//                )
//            }
//            .receive(on: DispatchQueue.main)
//            .assign(to: &$tangemPayCardDetailsViewModel)
//
//        transactionHistoryService
//            .itemsPublisher
//            .map { items in
//                let items = items
//                    .filter { $0.transactionType != .collateral }
//                    .enumerated()
//                    .compactMap { index, item in
//                        item.transactionViewModel(index: index)
//                    }
//
//                return .loaded(
//                    [
//                        .init(
//                            header: "All transactions",
//                            items: items
//                        ),
//                    ]
//                )
//            }
//            .receive(on: DispatchQueue.main)
//            .assign(to: &$tangemPayTransactionHistoryState)
//    }
//
//    func fetchNextTransactionHistoryPage() -> FetchMore? {
//        guard transactionHistoryService.canFetchMoreHistory else {
//            return nil
//        }
//
//        return FetchMore { [weak self] in
//            self?.loadNextHistoryPage()
//        }
//    }
//
//    private func reloadHistory() async {
//        guard historyReloadTask == nil else {
//            return
//        }
//
//        historyReloadTask = Task { [weak self] in
//            await self?.transactionHistoryService.reloadHistory()
//            self?.historyReloadTask = nil
//        }
//
//        await historyReloadTask?.value
//    }
//
//    private func loadNextHistoryPage() {
//        guard historyReloadTask == nil else {
//            return
//        }
//
//        historyReloadTask = Task { [weak self] in
//            await self?.transactionHistoryService.loadNextPage()
//            self?.historyReloadTask = nil
//        }
//    }
//}
//
//struct TangemPayMainView: View {
//    [REDACTED_USERNAME] var viewModel: TangemPayMainViewModel
//
//    var body: some View {
//        RefreshScrollView(stateObject: viewModel.refreshScrollViewStateObject) {
//            VStack(spacing: 14) {
//                MainHeaderView(viewModel: viewModel.mainHeaderViewModel)
//                    .fixedSize(horizontal: false, vertical: true)
//
//                if let tangemPayCardDetailsViewModel = viewModel.tangemPayCardDetailsViewModel {
//                    TangemPayCardDetailsView(viewModel: tangemPayCardDetailsViewModel)
//                }
//
//                TransactionsListView(
//                    state: viewModel.tangemPayTransactionHistoryState,
//                    exploreAction: nil,
//                    exploreTransactionAction: { _ in },
//                    reloadButtonAction: {},
//                    isReloadButtonBusy: false,
//                    fetchMore: viewModel.fetchNextTransactionHistoryPage()
//                )
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.top, 12)
//        }
//        .background(Colors.Background.secondary)
//    }
//}
//
//import TangemVisa
//
//private extension TangemPayTransactionHistoryResponse.Transaction {
//    func transactionViewModel(index: Int) -> TransactionViewModel? {
//        switch record {
//        case .spend(let spend):
//            return TransactionViewModel(
//                hash: "N/A",
//                index: index,
//                interactionAddress: .custom(message: spend.enrichedMerchantCategory ?? spend.merchantCategory ?? spend.merchantCategoryCode),
//                timeFormatted: (spend.postedAt ?? spend.authorizedAt).formatted(date: .numeric, time: .shortened),
//                amount: "\(-spend.amount) \(spend.currency.uppercased())",
//                isOutgoing: index % 2 == 0,
//                transactionType: .tangemPay(
//                    name: spend.enrichedMerchantName ?? spend.merchantName ?? "Card payment",
//                    icon: spend.enrichedMerchantIcon
//                ),
//                status: .confirmed
//            )
//
//        case .collateral:
//            return nil
//
//        case .payment(let payment):
//            let isOutgoing = payment.amount < 0
//
//            return TransactionViewModel(
//                hash: "N/A",
//                index: index,
//                interactionAddress: .custom(message: "Transfers"),
//                timeFormatted: payment.postedAt.formatted(date: .numeric, time: .shortened),
//                amount: "\(payment.amount) \(payment.currency.uppercased())",
//                isOutgoing: isOutgoing,
//                transactionType: .tangemPayTransfer(name: isOutgoing ? "Withdraw" : "Deposit"),
//                status: .confirmed
//            )
//
//        case .fee(let fee):
//            return TransactionViewModel(
//                hash: "N/A",
//                index: index,
//                interactionAddress: .custom(message: "Service fees"),
//                timeFormatted: fee.postedAt.formatted(date: .numeric, time: .shortened),
//                amount: "\(-fee.amount) \(fee.currency.uppercased())",
//                isOutgoing: true,
//                transactionType: .tangemPay(name: "Fee", icon: nil),
//                status: .confirmed
//            )
//        }
//    }
//}
