//
//  FeedWidgetSheetPresenter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemFoundation
import TangemUI
import TangemUIUtils

final class FeedWidgetSheetPresenter: ObservableObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.floatingSheetPresentingStateProvider) private var sheetStateProvider: FloatingSheetPresentingStateProvider

    @Published private(set) var walletSelector: WalletSelector?
    @Published var isWalletSelectorPresented = false

    private weak var presentedWidgetSheet: AnyObject?
    private var walletSelectionCompletion: (@MainActor () -> Void)?
    private var bag = Set<AnyCancellable>()

    var isPresenting: Bool { presentedWidgetSheet != nil || walletSelector != nil }

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

    /// Closes the wallet selector without going on to the chosen wallet.
    func dropWalletSelector() {
        walletSelectionCompletion = nil
        isWalletSelectorPresented = false
        walletSelector = nil
    }
}

extension FeedWidgetSheetPresenter {
    enum WalletSelector {
        case accounts(AccountSelectorViewModel)
        case referral(FeedReferralWalletSelectorViewModel)
    }
}

@MainActor
extension FeedWidgetSheetPresenter {
    func presentWalletSelector(wallets: [UserWalletModel], onSelect: @escaping @MainActor (UserWalletModel) -> Void) {
        let viewModel = AccountSelectorViewModel(
            userWalletModels: wallets,
            preferredDisplayMode: .wallets
        ) { [weak self] selection in
            Task { @MainActor [weak self] in
                self?.completeWalletSelection { onSelect(selection.userWalletModel) }
            }
        }
        present(.accounts(viewModel))
    }

    func presentReferralWalletSelector(
        candidates: [FeedReferralWalletCandidate],
        candidatesPublisher: AnyPublisher<[FeedReferralWalletCandidate], Never>,
        onSelect: @escaping @MainActor (UserWalletId) -> Void
    ) {
        let viewModel = FeedReferralWalletSelectorViewModel(
            candidates: candidates,
            candidatesPublisher: candidatesPublisher
        ) { [weak self] walletId in
            Task { @MainActor [weak self] in
                self?.completeWalletSelection { onSelect(walletId) }
            }
        }
        present(.referral(viewModel))
    }

    func walletSelectorDidDismiss() {
        let completion = walletSelectionCompletion
        walletSelectionCompletion = nil
        walletSelector = nil
        isWalletSelectorPresented = false
        completion?()
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

@MainActor
private extension FeedWidgetSheetPresenter {
    func present(_ selector: WalletSelector) {
        guard walletSelector == nil else { return }

        UIApplication.shared.endEditing()
        walletSelector = selector
        isWalletSelectorPresented = true
    }

    func completeWalletSelection(_ completion: @escaping @MainActor () -> Void) {
        guard isWalletSelectorPresented else { return }

        // The next screen waits until the Modal has finished dismissing.
        walletSelectionCompletion = completion
        isWalletSelectorPresented = false
    }
}
