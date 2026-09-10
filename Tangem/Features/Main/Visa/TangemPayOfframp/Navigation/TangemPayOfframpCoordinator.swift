//
//  TangemPayOfframpCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

final class TangemPayOfframpCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: WithdrawHubViewModel?
    @Published var path: [Route] = []

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Shared state

    private(set) var recentRecipientsStore: TangemPayRecentRecipientsStore?
    private(set) var orderBuilder: TangemPayOfframpOrderBuilder?
    @Published private(set) var transferInputViewModel: TransferInputViewModel?

    private var tangemPayAccount: TangemPayAccount?
    private var bag: Set<AnyCancellable> = []

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        tangemPayAccount = options.tangemPayAccount

        let recentRecipientsStore = TangemPayRecentRecipientsStore(
            repository: CommonTangemPayBankAccountsRepository(
                customerService: options.tangemPayAccount.customerService
            ),
            cacheStorage: AppSettings.shared,
            customerWalletId: options.tangemPayAccount.userWalletId.stringValue
        )
        self.recentRecipientsStore = recentRecipientsStore

        rootViewModel = WithdrawHubViewModel(
            withdrawFlowResolver: TangemPayWithdrawFlowResolver(
                fundingFlowBuilder: options.fundingFlowBuilder,
                withdrawAvailabilityProvider: options.tangemPayAccount.withdrawAvailabilityProvider
            ),
            recentRecipientsStore: recentRecipientsStore,
            output: { [weak self] in
                self?.handle($0)
            }
        )

        bind()
    }

    func startWizard(recipient: TangemPayOfframpRecipient) {
        guard let tangemPayAccount else { return }

        let orderBuilder = TangemPayOfframpOrderBuilder(recipient: recipient)
        self.orderBuilder = orderBuilder

        let savedRecipientName = savedRecipientName(for: recipient)

        Task { @MainActor [weak self] in
            guard let self else { return }

            transferInputViewModel = TransferInputFactory.makeViewModel(
                orderBuilder: orderBuilder,
                tangemPayAccount: tangemPayAccount,
                recipient: recipient,
                savedRecipientName: savedRecipientName,
                output: { [weak self] in
                    self?.handle($0)
                }
            )

            path.append(.transferInput)
        }
    }
}

// MARK: - Coordinator Options

extension TangemPayOfframpCoordinator {
    struct Options {
        let tangemPayAccount: TangemPayAccount
        let fundingFlowBuilder: TangemPayFundingFlowBuilder
    }

    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}

// MARK: - Route

extension TangemPayOfframpCoordinator {
    enum Route: Hashable {
        case recentRecipients
        case transferInput
        case transferType
        case accountType
    }
}

// MARK: - Wizard lifetime

private extension TangemPayOfframpCoordinator {
    func bind() {
        $path
            .map { $0.contains(.transferInput) }
            .removeDuplicates()
            .filter { !$0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.orderBuilder = nil
                coordinator.transferInputViewModel = nil
            }
            .store(in: &bag)
    }

    func savedRecipientName(for recipient: TangemPayOfframpRecipient) -> String? {
        guard case .saved(let bankAccountId) = recipient else { return nil }

        return recentRecipientsStore?
            .recipients
            .first { $0.id == bankAccountId }
            .map { TangemPayRecipientNameFormatter.name(for: $0, style: .full) }
    }
}

// MARK: - Transfer input output

private extension TangemPayOfframpCoordinator {
    func handle(_ output: TransferInputViewModel.Output) {
        switch output {
        case .continueWizard:
            continueAfterTransferInput()

        case .close:
            dismiss(with: nil)
        }
    }
}

// MARK: - Wizard step output

extension TangemPayOfframpCoordinator {
    func handle(_ output: TransferTypeViewModel.Output) {
        switch output {
        case .continueWizard:
            path.append(.accountType)

        case .close:
            dismiss(with: nil)
        }
    }

    func handle(_ output: AccountTypeViewModel.Output) {
        switch output {
        case .continueWizard:
            // [REDACTED_TODO_COMMENT]
            break

        case .close:
            dismiss(with: nil)
        }
    }
}

// MARK: - Wizard routing

private extension TangemPayOfframpCoordinator {
    func continueAfterTransferInput() {
        guard let orderBuilder else { return }

        switch orderBuilder.recipient {
        case .newIndividual:
            path.append(.transferType)

        case .newBusiness:
            path.append(.accountType)

        case .saved:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }
}

// MARK: - Withdraw hub output

private extension TangemPayOfframpCoordinator {
    func handle(_ output: WithdrawHubViewModel.Output) {
        switch output {
        case .withdrawNote(let parameters):
            Task { @MainActor in
                let viewModel = TangemPayWithdrawNoteSheetViewModel(
                    parameters: parameters,
                    coordinator: self
                )
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .withdrawInProgress:
            Task { @MainActor in
                let viewModel = TangemPayWithdrawInProgressSheetViewModel(coordinator: self)
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .noDepositAddress:
            Task { @MainActor in
                let viewModel = TangemPayNoDepositAddressSheetViewModel(coordinator: self)
                floatingSheetPresenter.enqueue(sheet: viewModel)
            }

        case .allRecipients:
            path.append(.recentRecipients)

        case .startWizard(let recipient):
            startWizard(recipient: recipient)

        case .close:
            dismiss(with: nil)
        }
    }

    func openSwap(parameters: PredefinedSwapParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] options in
            self?.sendCoordinator = nil

            switch options {
            case .none, .closeButtonTap, .openSwap:
                break
            case .openFeeCurrency(let feeCurrency):
                self?.dismiss(with: feeCurrency)
            }
        }

        let coordinator = SendCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(type: .swap(parameters), source: .main))
        sendCoordinator = coordinator
    }
}

// MARK: - TangemPayWithdrawNoteSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayWithdrawNoteSheetRoutable {
    func closeWithdrawNoteSheetPopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openWithdrawal(parameters: PredefinedSwapParameters) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            openSwap(parameters: parameters)
        }
    }
}

// MARK: - TangemPayWithdrawInProgressSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayWithdrawInProgressSheetRoutable {
    func closeWithdrawInProgressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayNoDepositAddressSheetRoutable

extension TangemPayOfframpCoordinator: TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
