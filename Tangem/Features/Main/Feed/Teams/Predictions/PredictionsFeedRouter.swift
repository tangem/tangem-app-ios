//
//  PredictionsFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol PredictionsFeedRoutable: AnyObject {
    func openPolymarket(wallets: [UserWalletModel])
}

final class PredictionsFeedRouter: PredictionsFeedRoutable {
    private weak var host: (any FeedHostRoutable)?
    private let widgetSheetPresenter: FeedWidgetSheetPresenter

    init(host: (any FeedHostRoutable)?, widgetSheetPresenter: FeedWidgetSheetPresenter) {
        self.host = host
        self.widgetSheetPresenter = widgetSheetPresenter
    }

    func openPolymarket(wallets: [UserWalletModel]) {
        Task { @MainActor [weak self] in
            guard let self, !widgetSheetPresenter.isPresenting else { return }

            if wallets.count > 1 {
                presentWalletSelector(wallets)
            } else if let wallet = wallets.first {
                host?.openPolymarket(userWalletModel: wallet)
            }
        }
    }
}

@MainActor
private extension PredictionsFeedRouter {
    func presentWalletSelector(_ wallets: [UserWalletModel]) {
        let viewModel = PolymarketWalletSelectorViewModel(
            userWalletModels: wallets,
            onSelect: { [weak self] wallet in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    widgetSheetPresenter.dismiss()
                    host?.openPolymarket(userWalletModel: wallet)
                }
            },
            onClose: { [weak self] in
                Task { @MainActor [weak self] in self?.widgetSheetPresenter.dismiss() }
            }
        )
        widgetSheetPresenter.enqueue(viewModel)
    }
}
