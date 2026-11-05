//
//  UserWalletLinkSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUI

@MainActor
final class UserWalletLinkSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.userWalletLinker) private var linker: any UserWalletLinker
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: any FloatingSheetPresentingStateProvider
    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    @Published private(set) var isLinking = false

    let title = Localization.warningLinkWalletTitle
    let description: String
    let buttonTitle: String
    let signingButtonType: SigningActionButtonViewType

    private let userWalletModel: any UserWalletModel
    private var onFinish: ((UserWalletLinkResult) -> Void)?
    private var linkTask: Task<Void, Never>?
    private var sheetRemovalSubscription: AnyCancellable?

    init(userWalletModel: any UserWalletModel, onFinish: @escaping (UserWalletLinkResult) -> Void) {
        let isCardWallet = userWalletModel.config.hasFeature(.nfcInteraction)

        description = isCardWallet ? Localization.warningLinkWalletColdMessage : Localization.warningLinkWalletHotMessage
        buttonTitle = isCardWallet ? Localization.commonScanCard : Localization.commonConfirm
        signingButtonType = SigningActionButtonViewTypeBuilder().build(config: userWalletModel.config)
        self.userWalletModel = userWalletModel
        self.onFinish = onFinish

        finishWhenSheetIsRemoved()
    }

    deinit {
        linkTask?.cancel()
    }

    func link() {
        guard !isLinking else {
            return
        }

        isLinking = true

        linkTask = runTask(in: self) { viewModel in
            do throws(UserWalletLinkError) {
                try await viewModel.linker.link(viewModel.userWalletModel)
                viewModel.finish(with: .linked)
            } catch {
                viewModel.handleLinkError(error)
            }
        }
    }

    func close() {
        finish(with: .dismissed)
    }
}

// MARK: - Private methods

private extension UserWalletLinkSheetViewModel {
    func finishWhenSheetIsRemoved() {
        sheetRemovalSubscription = sheetStateProvider.activeSheetIdPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                guard !self.sheetStateProvider.containsSheet(withId: self.id) else {
                    return
                }

                self.finish(with: .dismissed)
            }
    }

    func handleLinkError(_ error: UserWalletLinkError) {
        switch error {
        case .cancelled:
            isLinking = false
        case .notSupported, .failed:
            if finish(with: .dismissed) {
                presentErrorAlert()
            }
        }
    }

    @discardableResult
    func finish(with result: UserWalletLinkResult) -> Bool {
        guard let onFinish else {
            return false
        }

        self.onFinish = nil
        sheetRemovalSubscription = nil
        linkTask?.cancel()
        floatingSheetPresenter.removeSheet(withId: id)

        onFinish(result)

        return true
    }

    func presentErrorAlert() {
        alertPresenter.present(alert: AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: Localization.commonTryAgainLater,
            primaryButton: .default(Text(Localization.commonOk))
        ))
    }
}
