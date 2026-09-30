//
//  FeedWidgetSheetPresenter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

final class FeedWidgetSheetPresenter {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider

    private weak var presentedWidgetSheet: AnyObject?
    private var bag = Set<AnyCancellable>()

    var isPresenting: Bool { presentedWidgetSheet != nil }

    init() {
        sheetStateProvider
            .hasPresentedSheetPublisher
            .filter { !$0 }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { presenter, _ in
                presenter.presentedWidgetSheet = nil
            }
            .store(in: &bag)
    }
}

@MainActor
extension FeedWidgetSheetPresenter {
    func presentWalletSelector(wallets: [UserWalletModel], onSelect: @escaping @MainActor (UserWalletModel) -> Void) {
        let selector = AccountSelectorViewModel(
            userWalletModels: wallets,
            preferredDisplayMode: .wallets
        ) { [weak self] selection in
            Task { @MainActor [weak self] in
                guard let self else { return }

                dismiss()
                onSelect(selection.userWalletModel)
            }
        }
        let viewModel = WalletSelectorSheetViewModel(
            accountSelectorViewModel: selector,
            close: { [weak self] in self?.dismiss() }
        )
        enqueue(viewModel)
    }

    func enqueue(_ sheet: some FloatingSheetContentViewModel & AnyObject) {
        presentedWidgetSheet = sheet
        floatingSheetPresenter.enqueue(sheet: sheet)
    }

    func dismiss() {
        presentedWidgetSheet = nil
        floatingSheetPresenter.removeActiveSheet()
    }
}
