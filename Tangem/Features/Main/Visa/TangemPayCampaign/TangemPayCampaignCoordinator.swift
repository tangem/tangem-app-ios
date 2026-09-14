//
//  TangemPayCampaignCoordinator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemUI

final class TangemPayCampaignCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: TangemPayCampaignViewModel?
    @Published var legalDocumentViewModel: WebViewContainerViewModel?

    private var cardsLimitUserWalletModel: UserWalletModel?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = TangemPayCampaignViewModel(campaignKey: options.campaignKey, coordinator: self)
    }
}

// MARK: - Options

extension TangemPayCampaignCoordinator {
    struct Options {
        let campaignKey: String
    }

    enum OutputOptions {
        case close
        case finished(userWalletModel: UserWalletModel)
        case finishedWithPlanSelection(userWalletModel: UserWalletModel)
    }
}

// MARK: - TangemPayCampaignRoutable

extension TangemPayCampaignCoordinator: TangemPayCampaignRoutable {
    func openWalletSelector(
        from userWalletModels: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    ) {
        let viewModel = TangemPayWalletSelectorViewModel(
            userWalletModels: userWalletModels,
            onSelect: { [weak self] userWalletModel in
                self?.dismissActiveSheet()
                onSelect(userWalletModel)
            },
            onClose: { [weak self] in
                self?.dismissActiveSheet()
            }
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openLegalDocument(url: URL) {
        legalDocumentViewModel = WebViewContainerViewModel(url: url, title: "", withCloseButton: true)
    }

    func openCardsLimitSheet(canUpgradePlan: Bool, userWalletModel: UserWalletModel) {
        cardsLimitUserWalletModel = userWalletModel

        Task { @MainActor in
            if canUpgradePlan {
                floatingSheetPresenter.enqueue(sheet: TangemPayCardsLimitReachedSheetViewModel(coordinator: self))
            } else {
                floatingSheetPresenter.enqueue(sheet: TangemPayMaximumCardsIssuedSheetViewModel(coordinator: self))
            }
        }
    }

    func closeCampaign() {
        dismiss(with: .close)
    }

    func finishCampaign(userWalletModel: UserWalletModel) {
        dismiss(with: .finished(userWalletModel: userWalletModel))
    }
}

// MARK: - TangemPayCardsLimitReachedSheetRoutable

extension TangemPayCampaignCoordinator: TangemPayCardsLimitReachedSheetRoutable {
    func closeCardsLimitReachedSheet() {
        dismissActiveSheet()
    }

    func cardsLimitReachedSheetDidRequestPlanUpgrade() {
        dismissActiveSheet()

        guard let cardsLimitUserWalletModel else { return }

        dismiss(with: .finishedWithPlanSelection(userWalletModel: cardsLimitUserWalletModel))
    }
}

// MARK: - TangemPayMaximumCardsIssuedSheetRoutable

extension TangemPayCampaignCoordinator: TangemPayMaximumCardsIssuedSheetRoutable {
    func closeMaximumCardsIssuedSheet() {
        dismissActiveSheet()
    }
}

// MARK: - Private

private extension TangemPayCampaignCoordinator {
    func dismissActiveSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
