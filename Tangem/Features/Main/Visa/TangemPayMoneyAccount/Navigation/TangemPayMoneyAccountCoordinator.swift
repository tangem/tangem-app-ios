//
//  TangemPayMoneyAccountCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import TangemPay
import TangemUI
import TangemVisa

final class TangemPayMoneyAccountCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager)
    private var safariManager: SafariManager

    @Injected(\.mailComposePresenter)
    private var mailPresenter: MailComposePresenter

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Injected(\.floatingSheetPresentingStateProvider)
    private var sheetStateProvider: any FloatingSheetPresentingStateProvider

    @Injected(\.cryptoAccountsGlobalStateProvider)
    private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    // MARK: - Child coordinators

    @Published var tokenDetailsCoordinator: TokenDetailsCoordinator? = nil
    @Published var contactManagementCoordinator: AddressBookContactManagementCoordinator? = nil
    @Published var sendCoordinator: SendCoordinator? = nil

    // MARK: - Modals

    @Published var addFundsViewModel: TangemPayMoneyAccountAddFundsViewModel? = nil
    @Published var accountDetailsViewModel: TangemPayVirtualAccountDetailsViewModel? = nil

    private(set) var options: Options!

    var isWithdrawHubPresenting = false
    var isYieldModePresenting = false

    private var pendingAddFundsOption: TangemPayMoneyAccountAddFundsOption?
    private var bankDetailsTask: Task<Void, Never>?
    private var safariHandle: SafariHandle?
    private var transactionDetailsPresentationTask: Task<Void, Never>?
    private var transactionDetailsSheetId: String?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options
    }
}

// MARK: - Options

extension TangemPayMoneyAccountCoordinator {
    struct Options {
        let userWalletModel: any UserWalletModel
        let moneyAccount: any TangemPayMoneyAccountModel
    }
}

// MARK: - Route

extension TangemPayMoneyAccountCoordinator {
    enum Route: Hashable {}
}

// MARK: - Money Account Output

extension TangemPayMoneyAccountCoordinator {
    func handle(_ output: TangemPayMoneyAccountViewModel.Output) {
        switch output {
        case .topup:
            openAddFunds()
        case .withdraw: break
        case .openTransactionDetails(let id):
            openTransactionDetails(id: id)
        }
    }
}

// MARK: - Add funds

extension TangemPayMoneyAccountCoordinator {
    func addFundsDidDismiss() {
        guard let option = pendingAddFundsOption else { return }

        pendingAddFundsOption = nil
        openAddFundsFlow(for: option)
    }
}

private extension TangemPayMoneyAccountCoordinator {
    func openAddFunds() {
        addFundsViewModel = TangemPayMoneyAccountAddFundsViewModel { [weak self] option in
            self?.pendingAddFundsOption = option
            self?.addFundsViewModel = nil
        }
    }

    func openAddFundsFlow(for option: TangemPayMoneyAccountAddFundsOption) {
        switch option {
        case .swap:
            openSwap()
        case .receive:
            openReceive()
        case .bankTransfer:
            openBankDetails()
        }
    }

    func openSwap() {
        let parameters = TangemPayMoneyAccountAddFundsSwapPredefinedParametersBuilder(
            userWalletModel: options.userWalletModel,
            moneyAccount: options.moneyAccount
        ).make()

        let coordinator = makeSendCoordinator()
        coordinator.start(with: .init(type: .swap(parameters), source: .main))
        sendCoordinator = coordinator
    }

    func openReceive() {
        let moneyAccount = options.moneyAccount
        let viewModel = ReceiveMainViewModel(
            options: .init(
                tokenItem: moneyAccount.tokenItem,
                flow: .crypto,
                addressTypesProvider: SingleAddressReceiveAddressTypesProvider(
                    address: moneyAccount.walletModel.defaultAddressString,
                    colorScheme: .whiteBlack
                )
            ),
            receiveTokenWithdrawNoticeInteractor: TangemPayReceiveTokenWithdrawNoticeInteractor()
        )
        viewModel.start()

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - Bank transfer

private extension TangemPayMoneyAccountCoordinator {
    func loadBankCredentials() async throws -> TangemPayBankCredentialsResponse? {
        let moneyAccount = options.moneyAccount

        if let credentials = moneyAccount.bankCredentials {
            return credentials
        }

        try await moneyAccount.loadBankCredentials()
        return moneyAccount.bankCredentials
    }

    func openBankDetails() {
        guard bankDetailsTask == nil else { return }

        bankDetailsTask = Task { @MainActor [weak self] in
            await self?.loadAndOpenAccountDetails()
            self?.bankDetailsTask = nil
        }
    }

    @MainActor
    func loadAndOpenAccountDetails() async {
        do {
            if let credentials = try await loadBankCredentials() {
                openAccountDetails(credentials: credentials)
                return
            }
        } catch {
            VisaLogger.error("Failed to load money account bank credentials", error: error)
        }

        openBankDetailsErrorPopup()
    }

    @MainActor
    func openAccountDetails(credentials: TangemPayBankCredentialsResponse) {
        let fees = TangemPayVirtualAccountFee(credentials: credentials).map { [$0] } ?? []

        accountDetailsViewModel = TangemPayVirtualAccountDetailsViewModel(
            credentials: credentials,
            feesSource: .known(fees),
            onClose: { [weak self] in
                self?.accountDetailsViewModel = nil
            }
        )
    }

    @MainActor
    func openBankDetailsErrorPopup() {
        let viewModel = TangemPayVirtualAccountBankDetailsErrorPopupViewModel(
            loadBankCredentials: { [weak self] in try await self?.loadBankCredentials() },
            coordinator: self
        )

        floatingSheetPresenter.enqueue(sheet: viewModel)
    }
}

// MARK: - TangemPayVirtualAccountBankDetailsErrorPopupRoutable

extension TangemPayMoneyAccountCoordinator: TangemPayVirtualAccountBankDetailsErrorPopupRoutable {
    func virtualAccountDidLoadBankCredentials(_ credentials: TangemPayBankCredentialsResponse) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            openAccountDetails(credentials: credentials)
        }
    }

    func virtualAccountBankDetailsErrorPopupDidRequestSupport() {
        let subject = VisaEmailSubject.usdAccountGeneralHelp
        let dataCollector = TangemPayMoneyAccountSupportDataCollector(
            customerId: options.moneyAccount.customerId,
            accountId: options.moneyAccount.accountId
        )
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: subject).recipient,
            emailType: .visaFeedback(subject: subject)
        )

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func closeVirtualAccountSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - SendFeeCurrencyNavigating

extension TangemPayMoneyAccountCoordinator: SendFeeCurrencyNavigating {}

// MARK: - Transaction details

private extension TangemPayMoneyAccountCoordinator {
    var isTransactionDetailsSheetAlive: Bool {
        transactionDetailsSheetId.map { sheetStateProvider.containsSheet(withId: $0) } ?? false
    }

    func openTransactionDetails(id: TransactionRecord.ID) {
        guard transactionDetailsPresentationTask == nil, !isTransactionDetailsSheetAlive else { return }

        transactionDetailsPresentationTask = Task { @MainActor [weak self] in
            guard let self else { return }

            let viewModel = makeTransactionDetailsViewModel(id: id)
            await viewModel.prepareForPresentation()

            guard !Task.isCancelled else { return }

            transactionDetailsSheetId = viewModel.id
            floatingSheetPresenter.enqueue(sheet: viewModel)
            transactionDetailsPresentationTask = nil
        }
    }

    @MainActor
    func makeTransactionDetailsViewModel(id: TransactionRecord.ID) -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(
            id: id,
            walletModel: options.moneyAccount.walletModel,
            userWalletInfo: options.userWalletModel.userWalletInfo,
            isAccountsMode: cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple,
            addressBookManager: options.userWalletModel.addressBookManager,
            addressBookAnalyticsLogger: CommonAddressBookAnalyticsLogger(),
            routable: self
        )
    }

    func openTokenDetails(
        walletModel: any WalletModel,
        userWalletModel: any UserWalletModel
    ) {
        guard let account = walletModel.account else {
            let message = "Inconsistent state: WalletModel '\(walletModel.name)' has no account in accounts-enabled build"
            AppLogger.error(error: message)
            return
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        })

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: account.walletModelsManager,
                userTokensManager: account.userTokensManager,
                addressBookManager: userWalletModel.addressBookManager,
                walletModel: walletModel
            )
        )

        tokenDetailsCoordinator = coordinator
    }
}

// MARK: - TransactionDetailsRoutable

extension TangemPayMoneyAccountCoordinator: TransactionDetailsRoutable {
    func openTransactionDetailsURL(_ url: URL) {
        Task { @MainActor [self] in
            floatingSheetPresenter.pauseSheetsDisplaying()
            safariHandle = safariManager.openURL(
                url,
                configuration: .init(),
                onDismiss: { [weak self] in
                    self?.floatingSheetPresenter.resumeSheetsDisplaying()
                },
                onSuccess: { _ in }
            )
        }
    }

    func shareFromTransactionDetails(text: String) {
        Task { @MainActor [self] in
            floatingSheetPresenter.pauseSheetsDisplaying()
            let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            controller.completionWithItemsHandler = { [weak self] _, _, _, _ in
                self?.floatingSheetPresenter.resumeSheetsDisplaying()
            }
            AppPresenter.shared.show(controller)
        }
    }

    #if INTERNAL || DEBUG
    func openTransactionDetailsDebug(_ info: TransactionDetailsDebugInfo) {
        Task { @MainActor [self] in
            floatingSheetPresenter.pauseSheetsDisplaying()

            let viewModel = TransactionDetailsDebugViewModel(info: info)
            let controller = UIHostingController(rootView: TransactionDetailsDebugView(viewModel: viewModel))
            controller.modalPresentationStyle = .overFullScreen

            viewModel.onClose = { [weak self, weak controller] in
                controller?.dismiss(animated: true) {
                    self?.floatingSheetPresenter.resumeSheetsDisplaying()
                }
            }

            AppPresenter.shared.show(controller)
        }
    }
    #endif

    func openAddContactFromTransactionDetails(addressBookWallet: AddressBookWallet, prefilledEntries: [AddressBookEntryDraft]) {
        Task { @MainActor in
            floatingSheetPresenter.pauseSheetsDisplaying()
            openAddContact(addressBookWallet: addressBookWallet, prefilledEntries: prefilledEntries)
        }
    }

    func closeTransactionDetails() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openTokenFromTransactionDetails(walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            openTokenDetails(walletModel: walletModel, userWalletModel: userWalletModel)
        }
    }
}

// MARK: - AddressBookContactNavigating

extension TangemPayMoneyAccountCoordinator: AddressBookContactNavigating {
    var addressBookAnalyticsSource: AddressBookAnalyticsSource { .transactionDetails }

    func contactManagementDidDismiss() {
        Task { @MainActor in
            floatingSheetPresenter.resumeSheetsDisplaying()
        }
    }
}
