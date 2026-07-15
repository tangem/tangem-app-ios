//
//  CampaignCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI

protocol CampaignRoutable: AnyObject {
    func closeCampaign()
    func openLearnMore(url: URL)
}

final class CampaignCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider
    @Injected(\.safariManager) private var safariManager: SafariManager

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private var safariHandle: SafariHandle?
    private var isSafariPresented = false
    private var sheetDismissSubscription: AnyCancellable?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let viewModel = CampaignViewModel(
            campaignId: options.campaignId,
            coordinator: self,
            cashbackPromoService: CashbackPromoService()
        )

        subscribeToSheetDismiss()

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - Options

extension CampaignCoordinator {
    struct Options {
        let campaignId: String
    }
}

// MARK: - Private

private extension CampaignCoordinator {
    func subscribeToSheetDismiss() {
        sheetDismissSubscription = sheetStateProvider.hasPresentedSheetPublisher
            .drop(while: { !$0 })
            .filter { [weak self] hasPresentedSheet in
                !hasPresentedSheet && self?.isSafariPresented == false
            }
            .first()
            .sink { [weak self] _ in
                self?.dismiss()
            }
    }

    func resumeSheetAfterSafari() {
        isSafariPresented = false

        Task { @MainActor in
            floatingSheetPresenter.resumeSheetsDisplaying()
        }
    }
}

// MARK: - CampaignRoutable

extension CampaignCoordinator: CampaignRoutable {
    func closeCampaign() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            dismiss()
        }
    }

    func openLearnMore(url: URL) {
        Task { @MainActor in
            isSafariPresented = true
            floatingSheetPresenter.pauseSheetsDisplaying()

            safariHandle = safariManager.openURL(
                url,
                configuration: .init(),
                onDismiss: { [weak self] in self?.resumeSheetAfterSafari() },
                onSuccess: { [weak self] _ in self?.resumeSheetAfterSafari() }
            )
        }
    }
}
