//
//  TangemPayMoneyAccountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUI
import TangemUIUtils

@MainActor
final class TangemPayMoneyAccountViewModel: ObservableObject {
    @Published private(set) var stateModel: TangemPayMoneyAccountStateModel
    @Published private(set) var menuSections: [[TangemPayMoneyAccountMenuItem]] = []
    @Published var alert: AlertBinder?

    private(set) lazy var refreshScrollState = RefreshScrollViewStateObject { [weak self] in
        await self?.refreshState()
    }

    @Injected(\.mailComposePresenter)
    private var mailPresenter: MailComposePresenter

    @Injected(\.safariManager)
    private var safariManager: SafariManager

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.cryptoAccountsGlobalStateProvider)
    private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    private let moneyAccount: any TangemPayMoneyAccountModel
    private let userWalletModel: any UserWalletModel
    private let output: (Output) -> Void

    private var bag = Set<AnyCancellable>()

    init(
        moneyAccount: any TangemPayMoneyAccountModel,
        userWalletModel: any UserWalletModel,
        output: @escaping (Output) -> Void
    ) {
        self.moneyAccount = moneyAccount
        self.userWalletModel = userWalletModel
        self.output = output

        stateModel = TangemPayMoneyAccountStateModel(
            balance: moneyAccount.fiatBalance,
            transactionHistory: .loading
        )

        menuSections = makeMenuSections()

        updateNotifications(for: moneyAccount.state)
        bindMoneyAccountState()
    }

    func loadState() async {
        await updateOnChainData()
    }

    func handleAction(_ action: TangemPayMoneyAccountAction) {
        switch action {
        case .topup:
            output(.topup)

        case .withdraw:
            output(.withdraw)

        case .selectMenuItem(let item):
            handleMenuItem(item)

        case .reloadTransactionHistory:
            reloadTransactionHistory()

        case .openTransactionDetails(let id):
            output(.openTransactionDetails(id: id))

        case .openExplorer:
            openExplorer()

        case .openYieldMode:
            break
        }
    }
}

// MARK: - Output

extension TangemPayMoneyAccountViewModel {
    enum Output {
        case topup
        case withdraw
        case openTransactionDetails(id: TransactionRecord.ID)
    }
}

// MARK: - Constants

private extension TangemPayMoneyAccountViewModel {
    enum Constants {
        static let usdRate: Decimal = 1
    }
}

// MARK: - Bindings

private extension TangemPayMoneyAccountViewModel {
    var addressBookContactsPublisher: AnyPublisher<[AddressBookContact], Never> {
        AddressBookContactsAggregator
            .contactsPublisher()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var tangemPayDepositOwnersPublisher: some Publisher<[TangemPayDepositOwner], Never> {
        TangemPayDepositOwnersPublisherFactory.makePublisher(userWalletRepository: userWalletRepository)
    }

    func bindMoneyAccountState() {
        moneyAccount.fiatBalancePublisher
            .receiveOnMain()
            .sink { [weak self] balance in
                self?.stateModel.balance = balance
            }
            .store(in: &bag)

        moneyAccount.transactionHistoryPublisher
            .combineLatest(addressBookContactsPublisher, tangemPayDepositOwnersPublisher)
            .receiveOnMain()
            .sink { [weak self] newState, contacts, tangemPayDepositOwners in
                self?.updateTransactionHistory(
                    to: newState,
                    contacts: contacts,
                    tangemPayDepositOwners: tangemPayDepositOwners
                )
            }
            .store(in: &bag)

        moneyAccount.statePublisher
            .receiveOnMain()
            .sink { [weak self] state in
                self?.updateNotifications(for: state)
            }
            .store(in: &bag)
    }
}

// MARK: - Refresh State

private extension TangemPayMoneyAccountViewModel {
    func refreshState() async {
        async let accountStateUpdate: Void = moneyAccount.refreshState()
        async let transactionHistoryUpdate: Void = moneyAccount.updateTransactionHistory()

        _ = await (accountStateUpdate, transactionHistoryUpdate)
    }

    func updateOnChainData() async {
        async let balanceUpdate: Void = moneyAccount.updateBalance()
        async let transactionHistoryUpdate: Void = moneyAccount.updateTransactionHistory()

        _ = await (balanceUpdate, transactionHistoryUpdate)
    }
}

// MARK: - Notifications

private extension TangemPayMoneyAccountViewModel {
    var mainButtonIcon: MainButton.Icon? {
        SigningActionButtonViewTypeBuilder().build(config: userWalletModel.config).mainButtonIcon
    }

    func updateNotifications(for state: TangemPayLocalState?) {
        let notificationInputs = state?
            .errorNotificationEvent(icon: mainButtonIcon)
            .map { [makeNotificationInput(for: $0)] } ?? []

        stateModel.notificationBannerItems = MultiWalletNotificationBannerMapper().mapItems(notificationInputs)
        stateModel.isStale = !notificationInputs.isEmpty
    }

    func makeNotificationInput(for event: TangemPayNotificationEvent) -> NotificationViewInput {
        NotificationsFactory().buildNotificationInput(
            for: event,
            buttonAction: { [weak self] _, action in
                self?.handleNotificationButtonTap(action)
            }
        )
    }

    func handleNotificationButtonTap(_ action: NotificationButtonActionType) {
        switch action {
        case .renewTangemPaySession:
            renewSession()
        default:
            break
        }
    }

    func renewSession() {
        moneyAccount.renewSession(authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor) { [weak self] error in
            Task { @MainActor in
                self?.showRenewSessionErrorIfNeeded(error)
            }
        }
    }

    func showRenewSessionErrorIfNeeded(_ error: TangemPayAuthorizationError?) {
        guard let error, !error.isUserCancelled, userWalletModel.config.hasFeature(.nfcInteraction) else {
            return
        }

        alert = AlertBinder(
            title: Localization.commonError,
            message: error.serverErrorStatusCode == nil
                ? Localization.commonUnknownError
                : Localization.commonServerUnavailable
        )
    }
}

// MARK: - Transaction history

private extension TangemPayMoneyAccountViewModel {
    var isAccountsMode: Bool {
        cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple
    }

    func updateTransactionHistory(
        to newState: WalletModelTransactionHistoryState,
        contacts: [AddressBookContact],
        tangemPayDepositOwners: [TangemPayDepositOwner]
    ) {
        switch newState {
        case .notSupported:
            stateModel.transactionHistory = .notSupported
        case .notLoaded, .loading:
            if case .loaded = stateModel.transactionHistory {
                break
            }

            stateModel.transactionHistory = .loading
        case .error(let error):
            stateModel.transactionHistory = .error(error)
        case .loaded(let records):
            let transactionHistoryMapper = TransactionHistoryMapper(
                currencySymbol: moneyAccount.tokenItem.currencySymbol,
                blockchain: moneyAccount.tokenItem.blockchain,
                addressesProvider: moneyAccount,
                showSign: true,
                isToken: moneyAccount.tokenItem.isToken,
                stakingNetwork: nil
            )

            let subtitleOwnerResolver = SubtitleOwnerResolver(
                blockchain: moneyAccount.tokenItem.blockchain,
                currentUserWalletId: moneyAccount.userWalletId,
                isAccountsMode: isAccountsMode,
                contacts: contacts,
                tangemPayDepositOwners: tangemPayDepositOwners
            )

            let listItems = transactionHistoryMapper.mapTransactionListItem(
                from: records,
                groupingStyle: .day,
                dustFilter: TransactionHistoryDustFilter(usdRate: Constants.usdRate),
                subtitleOwnerResolver: subtitleOwnerResolver
            )

            stateModel.transactionHistory = .loaded(listItems)
        }

        updateFetchMore()
    }

    func reloadTransactionHistory() {
        Task { [weak self] in
            guard let self else { return }

            setTransactionHistoryReloading(true)
            await moneyAccount.reloadTransactionHistory()
            setTransactionHistoryReloading(false)
        }
    }

    func setTransactionHistoryReloading(_ isReloading: Bool) {
        stateModel.isTrxHistoryReloading = isReloading
        updateFetchMore()
    }

    func updateFetchMore() {
        guard moneyAccount.canLoadMoreTransactionHistory, !stateModel.isTrxHistoryReloading else {
            stateModel.fetchMore = nil
            return
        }

        stateModel.fetchMore = FetchMore { [weak self] in
            self?.loadNextTransactionHistoryPage()
        }
    }

    func loadNextTransactionHistoryPage() {
        Task { [weak self] in
            await self?.moneyAccount.loadTransactionHistory()
        }
    }

    func openExplorer() {
        guard let url = moneyAccount.explorerURL else {
            return
        }

        safariManager.openURL(url)
    }
}

// MARK: - Menu

private extension TangemPayMoneyAccountViewModel {
    func makeMenuSections() -> [[TangemPayMoneyAccountMenuItem]] {
        [
            [.termsAndFees, .support],
            // close_account item might be here
        ]
    }

    func handleMenuItem(_ item: TangemPayMoneyAccountMenuItem) {
        switch item {
        case .termsAndFees:
            safariManager.openURL(AppConstants.tangemPayTermsOfServiceURL)

        case .support:
            contactSupport(subject: .usdAccountGeneralHelp)

        case .closeAccount:
            break
        }
    }

    func contactSupport(subject: VisaEmailSubject) {
        let dataCollector = TangemPayMoneyAccountSupportDataCollector(
            customerId: moneyAccount.customerId,
            accountId: moneyAccount.accountId
        )
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: subject).recipient,
            emailType: .visaFeedback(subject: subject)
        )

        mailPresenter.present(viewModel: mailViewModel)
    }
}
