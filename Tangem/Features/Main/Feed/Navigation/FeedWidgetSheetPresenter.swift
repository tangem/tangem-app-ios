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

    @Published private(set) var selector: WidgetSelector?
    @Published var isSelectorPresented = false
    @Published private(set) var status: WidgetStatus?
    @Published var isStatusPresented = false

    private weak var presentedWidgetSheet: AnyObject?
    private var selectionCompletion: (@MainActor () -> Void)?
    private var bag = Set<AnyCancellable>()

    var isPresenting: Bool { presentedWidgetSheet != nil || selector != nil || status != nil }

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

    /// Closes the selector without going on to the next screen.
    func dropSelector() {
        selectionCompletion = nil
        isSelectorPresented = false
        selector = nil
    }

    func dropStatus() {
        isStatusPresented = false
        status = nil
    }
}

extension FeedWidgetSheetPresenter {
    enum WidgetSelector {
        case accounts(AccountSelectorViewModel)
        case referral(FeedReferralWalletSelectorViewModel)
        case accountType(AddAccountTypeSelectorViewModel)
    }

    enum WidgetStatus {
        case collectiblesRegionRestricted
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
                self?.completeSelection { onSelect(selection.userWalletModel) }
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
                self?.completeSelection { onSelect(walletId) }
            }
        }
        present(.referral(viewModel))
    }

    func presentAccountTypeSelector(_ viewModel: AddAccountTypeSelectorViewModel) {
        present(.accountType(viewModel))
    }

    /// Closes the selector and opens the next screen once it is gone, or right away when no selector is shown.
    func dismissSelector(then next: @escaping @MainActor () -> Void = {}) {
        guard selector != nil else {
            next()
            return
        }

        completeSelection(next)
    }

    func selectorDidDismiss() {
        let completion = selectionCompletion
        selectionCompletion = nil
        selector = nil
        isSelectorPresented = false
        completion?()
    }

    func presentStatus(_ status: WidgetStatus) {
        guard self.status == nil else { return }

        self.status = status
        isStatusPresented = true
    }

    func dismissStatus() {
        isStatusPresented = false
    }

    func statusDidDismiss() {
        status = nil
        isStatusPresented = false
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
    func present(_ selector: WidgetSelector) {
        guard self.selector == nil else { return }

        UIApplication.shared.endEditing()
        self.selector = selector
        isSelectorPresented = true
    }

    func completeSelection(_ completion: @escaping @MainActor () -> Void) {
        guard isSelectorPresented else { return }

        // The next screen waits until the Modal has finished dismissing.
        selectionCompletion = completion
        isSelectorPresented = false
    }
}
