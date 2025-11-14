//
//  TangemPayMainCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class TangemPayMainCoordinator: CoordinatorObject {
    let dismissAction: ExpressCoordinator.DismissAction
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: TangemPayMainViewModel?

    // MARK: - Child coordinators

    @Published var expressCoordinator: ExpressCoordinator?

    // MARK: - Child view models

    @Published var addToApplePayGuideViewModel: TangemPayAddToAppPayGuideViewModel?
    @Published var tangemPayPinViewModel: TangemPayPinViewModel?

    required init(
        dismissAction: @escaping ExpressCoordinator.DismissAction,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(
            userWalletInfo: options.userWalletInfo,
            tangemPayAccount: options.tangemPayAccount,
            cardNumberEnd: options.cardNumberEnd,
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayMainCoordinator {
    struct Options {
        let userWalletInfo: UserWalletInfo
        let tangemPayAccount: TangemPayAccount
        let cardNumberEnd: String
    }
}

// MARK: - TangemPayMainRoutable

extension TangemPayMainCoordinator: TangemPayMainRoutable {
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel) {
        addToApplePayGuideViewModel = TangemPayAddToAppPayGuideViewModel(
            tangemPayCardDetailsViewModel: viewModel,
            coordinator: self
        )
    }

    func openTangemPayPin() {
        tangemPayPinViewModel = TangemPayPinViewModel(coordinator: self)
    }

    func openTangemPayAddFundsSheet(input: TangemPayAddFundsSheetViewModel.Input) {
        let viewModel = TangemPayAddFundsSheetViewModel(input: input, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayNoDepositAddressSheet() {
        let viewModel = TangemPayNoDepositAddressSheetViewModel(coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayFreezeSheet(freezeAction: @escaping () -> Void) {
        let viewModel = TangemPayFreezeSheetViewModel(
            coordinator: self,
            freezeAction: freezeAction
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayTransactionDetailsSheet(transaction: TangemPayTransactionRecord) {
        let viewModel = TangemPayTransactionDetailsViewModel(transaction: transaction, coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - TangemPayNoDepositAddressSheetRoutable

extension TangemPayMainCoordinator: TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayFreezeSheetRoutable

extension TangemPayMainCoordinator: TangemPayFreezeSheetRoutable {
    func closeFreezeSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayAddToAppPayGuideRoutable

extension TangemPayMainCoordinator: TangemPayAddToAppPayGuideRoutable {
    func closeAddToAppPayGuide() {
        addToApplePayGuideViewModel = nil
    }
}

// MARK: - TangemPayPinRoutable

extension TangemPayMainCoordinator: TangemPayPinRoutable {
    func closeTangemPayPin() {
        tangemPayPinViewModel = nil
    }
}

// MARK: - TangemPayAddFundsSheetRoutable

extension TangemPayMainCoordinator: TangemPayAddFundsSheetRoutable {
    func addFundsSheetRequestReceive(viewModel: ReceiveMainViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func addFundsSheetRequestSwap(input: ExpressDependenciesDestinationInput) {
        let dismissAction: ExpressCoordinator.DismissAction = { [weak self] options in
            switch options {
            case .openFeeCurrency(let userWalletId, let feeTokenItem):
                self?.expressCoordinator = nil
                self?.dismiss(with: .openFeeCurrency(userWalletId: userWalletId, feeTokenItem: feeTokenItem))
            case .none:
                self?.expressCoordinator = nil
            }
        }

        let factory = CommonExpressModulesFactory(input: input)
        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            // Give some time to hide sheet with animation
            try? await Task.sleep(seconds: 0.2)
            expressCoordinator = coordinator
        }
    }

    func closeAddFundsSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayTransactionDetailsRoutable

extension TangemPayMainCoordinator: TangemPayTransactionDetailsRoutable {
    func transactionDetailsDidRequestClose() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func transactionDetailsDidRequestDispute(dataCollector: EmailDataCollector, subject: VisaEmailSubject) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.default.recipient,
            emailType: .visaFeedback(subject: subject)
        )

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}
