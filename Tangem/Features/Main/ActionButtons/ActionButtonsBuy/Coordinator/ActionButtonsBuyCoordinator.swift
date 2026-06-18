//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import UIKit

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    let dismissAction: Action<ActionButtonsBuyDismissPayload?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Published property

    @Published private(set) var viewState: RootViewState?

    @Published var addToPortfolioBottomSheetInfo: HotCryptoAddToPortfolioBottomSheetViewModel?

    // MARK: - Private property

    private var safariHandle: SafariHandle?
    private var userWalletModels: [UserWalletModel] = []

    required init(
        dismissAction: @escaping Action<ActionButtonsBuyDismissPayload?>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        userWalletModels = options.userWalletModels
        let tokenSelectorViewModel = makeTokenSelectorViewModel()
        viewState = .newTokenList(
            ActionButtonsBuyViewModel(
                userWalletModels: options.userWalletModels,
                tokenSelectorViewModel: tokenSelectorViewModel,
                coordinator: self
            )
        )
    }

    func dismiss() {
        dismiss(with: nil)
    }
}

// MARK: - ActionButtonsBuyRoutable

extension ActionButtonsBuyCoordinator: ActionButtonsBuyRoutable {
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.dismiss()
        }

        let sourceTokenFactory = CommonSendTransferableTokenFactory(
            userWalletInfo: input.userWalletInfo,
            walletModel: input.walletModel
        )
        let sourceToken = sourceTokenFactory.makeTransferableToken()

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            type: .onramp(sourceToken, parameters: parameters),
            source: .actionButtons
        )
        coordinator.start(with: options)
        viewState = .onramp(coordinator)
    }

    func openAddFunds(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) {
        Task { @MainActor [weak self] in
            guard let self,
                  let userWalletModel = userWalletModels.first(where: { $0.userWalletId == userWalletInfo.id })
            else {
                return
            }

            UIApplication.shared.endEditing()
            let viewModel = AddFundsViewModel(
                input: .init(
                    mode: .stack,
                    primaryAction: .goToToken,
                    walletModel: walletModel,
                    userWalletModel: userWalletModel
                ),
                coordinator: self
            )
            viewState = .addFunds(viewModel)
        }
    }

    func openAddToPortfolio(viewModel: HotCryptoAddToPortfolioBottomSheetViewModel) {
        addToPortfolioBottomSheetInfo = viewModel
    }

    func closeAddToPortfolio() {
        addToPortfolioBottomSheetInfo = nil
    }

    func openAddHotToken(hotToken: HotCryptoToken, userWalletModels: [UserWalletModel]) {
        Task { @MainActor in
            let configuration = HotCryptoAddTokenFlowConfigurationFactory.make(
                hotToken: hotToken,
                coordinator: self
            )

            let viewModel = AddTokenFlowViewModel(
                userWalletModels: userWalletModels,
                configuration: configuration,
                coordinator: self
            )

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - AddFundsRoutable

extension ActionButtonsBuyCoordinator: AddFundsRoutable {
    func addFundsRequestBuy(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        Task { @MainActor [weak self] in
            let input = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
            self?.openOnramp(input: input, parameters: .none)
        }
    }

    func addFundsRequestSwap(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        let helper = SwapPredefinedParametersHelper()
        guard let parameters = helper.makeParameters(
            walletModel: walletModel,
            userWalletInfo: userWalletModel.userWalletInfo,
            position: .automatic
        ) else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let sendCoordinator = SendCoordinator(dismissAction: { [weak self] _ in
                self?.dismiss()
            })
            sendCoordinator.start(with: .init(type: .swap(parameters), source: .actionButtons))
            viewState = .swap(sendCoordinator)
        }
    }

    func addFundsRequestReceive(viewModel: ReceiveMainViewModel) {
        Task { @MainActor [weak self] in
            self?.floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func addFundsRequestGoToToken(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        Task { @MainActor [weak self] in
            self?.dismiss(with: ActionButtonsBuyDismissPayload(walletModel: walletModel, userWalletModel: userWalletModel))
        }
    }

    func addFundsClose() {
        dismiss()
    }
}

// MARK: - HotCryptoAddTokenRoutable, AddTokenFlowRoutable

extension ActionButtonsBuyCoordinator: HotCryptoAddTokenRoutable, AddTokenFlowRoutable {
    func close() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: ToastConstants.topPadding),
                type: .temporary()
            )
    }
}

// MARK: - Options

extension ActionButtonsBuyCoordinator {
    struct Options {
        let userWalletModels: [UserWalletModel]
    }

    enum RootViewState: Equatable {
        case newTokenList(ActionButtonsBuyViewModel)
        case addFunds(AddFundsViewModel)
        case onramp(SendCoordinator)
        case swap(SendCoordinator)

        static func == (lhs: RootViewState, rhs: RootViewState) -> Bool {
            switch (lhs, rhs) {
            case (.newTokenList, .newTokenList): true
            case (.addFunds, .addFunds): true
            case (.onramp, .onramp): true
            case (.swap, .swap): true
            default: false
            }
        }
    }
}

// MARK: - Dismiss payload

struct ActionButtonsBuyDismissPayload {
    let walletModel: any WalletModel
    let userWalletModel: UserWalletModel
}

// MARK: - Factory method

private extension ActionButtonsBuyCoordinator {
    func makeTokenSelectorViewModel() -> TokenSelectorViewModel {
        .common(walletsProvider: .standardAccountsOnly(), availabilityProvider: .buy())
    }
}

// MARK: - Constants

private extension ActionButtonsBuyCoordinator {
    enum ToastConstants {
        static let topPadding: CGFloat = 52
    }
}
