//
//  CryptoFeedRouter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemUI

protocol CryptoFeedRoutable: AnyObject {
    func openToken(_ token: MarketsTokenModel)
    func openPulseTagFilter(with input: PulseTagFilterInput)
    func openMarketCapInfo(subject: MarketCapInfoSubject)
    func openPortfolioToken(_ walletModel: any WalletModel)
}

final class CryptoFeedRouter {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    private weak var navigation: (any FeedNavigation)?
    private weak var tagFilter: PulseTagFilterBottomSheetViewModel?
    private weak var marketCapInfo: MarketCapInfoBottomSheetViewModel?

    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
    }
}

// MARK: - CryptoFeedRoutable

extension CryptoFeedRouter: CryptoFeedRoutable {
    func openToken(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.navigation?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(info: token, style: .marketsSheet))
        navigation?.push(.token(coordinator))
    }

    func openPulseTagFilter(with input: PulseTagFilterInput) {
        Task { @MainActor [weak self] in
            guard let self, tagFilter == nil else {
                return
            }

            let viewModel = PulseTagFilterBottomSheetViewModel(
                input: input,
                onDismiss: { [weak self] in
                    self?.tagFilter = nil
                    self?.floatingSheetPresenter.removeActiveSheet()
                }
            )

            tagFilter = viewModel
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openMarketCapInfo(subject: MarketCapInfoSubject) {
        Task { @MainActor [weak self] in
            guard let self, marketCapInfo == nil else {
                return
            }

            let viewModel = MarketCapInfoBottomSheetViewModel(
                subject: subject,
                closeAction: { [weak self] in
                    self?.marketCapInfo = nil
                    self?.floatingSheetPresenter.removeActiveSheet()
                }
            )

            marketCapInfo = viewModel
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openPortfolioToken(_ walletModel: any WalletModel) {
        guard
            let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
            let accountModel = walletModel.account
        else {
            return
        }

        let coordinator = TokenDetailsCoordinator(
            dismissAction: { [weak self] _ in self?.navigation?.pop() },
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: accountModel.walletModelsManager,
                userTokensManager: accountModel.userTokensManager,
                addressBookManager: userWalletModel.addressBookManager,
                walletModel: walletModel,
                presentSource: .markets
            )
        )
        navigation?.push(.portfolioToken(coordinator))
    }
}
