//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - Published property

    @Published private(set) var viewState: RootViewState?

    @Published var addToPortfolioBottomSheetInfo: HotCryptoAddToPortfolioBottomSheetViewModel?

    // MARK: - Private property

    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let tokenSelectorViewModel = makeTokenSelectorViewModel()
        viewState = .newTokenList(
            ActionButtonsBuyViewModel(
                userWalletModels: options.userWalletModels,
                tokenSelectorViewModel: tokenSelectorViewModel,
                coordinator: self
            )
        )
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
        case onramp(SendCoordinator)

        static func == (lhs: RootViewState, rhs: RootViewState) -> Bool {
            switch (lhs, rhs) {
            case (.newTokenList, .newTokenList): true
            case (.onramp, .onramp): true
            default: false
            }
        }
    }
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
