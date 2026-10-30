//
//  CollectiblesFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol CollectiblesFeedRoutable: AnyObject {
    func openCollectibles(wallets: [UserWalletModel], isRegionRestricted: Bool)
}

final class CollectiblesFeedRouter: CollectiblesFeedRoutable {
    private weak var navigation: (any FeedNavigation)?
    private weak var host: (any FeedHostRoutable)?
    private let widgetSheetPresenter: FeedWidgetSheetPresenter

    @MainActor
    private var isOpeningCollectibles = false

    init(context: FeedContext, host: (any FeedHostRoutable)?, widgetSheetPresenter: FeedWidgetSheetPresenter) {
        navigation = context.navigation
        self.host = host
        self.widgetSheetPresenter = widgetSheetPresenter
    }

    func openCollectibles(wallets: [UserWalletModel], isRegionRestricted: Bool) {
        Task { @MainActor [weak self] in
            guard let self, let navigation, navigation.isAtRoot,
                  !widgetSheetPresenter.isPresenting, let wallet = wallets.first else { return }

            guard wallets.count > 1 else {
                openCollectibles(for: wallet, isRegionRestricted: isRegionRestricted)
                return
            }

            widgetSheetPresenter.presentWalletSelector(wallets: wallets) { [weak self] wallet in
                self?.openCollectibles(for: wallet, isRegionRestricted: isRegionRestricted)
            }
        }
    }
}

@MainActor
private extension CollectiblesFeedRouter {
    func openCollectibles(for wallet: UserWalletModel, isRegionRestricted: Bool) {
        guard !isOpeningCollectibles else { return }

        isOpeningCollectibles = true

        Task { @MainActor [weak self] in
            defer { self?.isOpeningCollectibles = false }

            guard let self else { return }

            let accountModel = wallet.collectiblesAccountModel()
            let outcome = await CollectiblesEntranceResolver.resolve(for: accountModel, isRegionRestricted: isRegionRestricted)

            guard let navigation, navigation.isFeedPresented, navigation.isAtRoot,
                  navigation.presented == nil, !widgetSheetPresenter.isPresenting else { return }

            switch outcome {
            case .open(let destination):
                let options = CollectiblesCoordinator.Options(
                    destination: destination,
                    userWalletModel: wallet,
                    accountModel: accountModel
                )

                host?.openCollectibles(with: options)

            case .regionRestricted:
                widgetSheetPresenter.enqueue(CollectiblesInfoSheetViewModel(model: .regionRestrictions))
            }
        }
    }
}
