//
//  PriceAlertsWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemFoundation
import TangemUI
import struct TangemUIUtils.AlertBinder

final class PriceAlertsWalletSelectorViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsPermission) private var pushNotificationsPermission: PushNotificationsPermissionService

    @Published private(set) var walletItems: [WalletSelectorItemViewModel] = []
    @Published private(set) var isSaveEnabled: Bool = false
    @Published var alert: AlertBinder?

    private let tokenId: PriceAlertTokenId
    private let closeAction: () -> Void

    /// Wallets that can manage this token's alert (locked wallets excluded), fixed for the sheet's lifetime.
    private var unlockedModels: [UserWalletModel] = []
    /// Real subscription state at open — the baseline Save diffs against.
    private var initiallySubscribedIds: Set<UserWalletId> = []
    /// Current checkbox selection (the desired state).
    private var selectedWalletIds: Set<UserWalletId> = []

    init(tokenId: PriceAlertTokenId, closeAction: @escaping () -> Void) {
        self.tokenId = tokenId
        self.closeAction = closeAction
        makeWalletItems()
        loadSubscriptionStates()
    }

    func closeTapped() {
        closeAction()
    }

    func saveTapped() {
        let toSubscribe = unlockedModels.filter {
            selectedWalletIds.contains($0.userWalletId) && !initiallySubscribedIds.contains($0.userWalletId)
        }
        let toUnsubscribe = unlockedModels.filter {
            !selectedWalletIds.contains($0.userWalletId) && initiallySubscribedIds.contains($0.userWalletId)
        }

        guard !toSubscribe.isEmpty || !toUnsubscribe.isEmpty else {
            return
        }

        runTask(in: self) { viewModel in
            // Push authorization is only required when the change adds new subscriptions.
            if !toSubscribe.isEmpty {
                guard await viewModel.pushNotificationsPermission.ensureAuthorized() else {
                    await viewModel.presentEnablePushSettingsAlert()
                    return
                }
            }

            do {
                // Apply the diff per wallet via its own provider so each optimistic state stays correct.
                // A single atomic POST with all walletIds is deferred to the final BE contract (OQ-1).
                for model in toSubscribe {
                    try await model.priceAlertsSubscriptionsProvider.subscribe(
                        tokenId: viewModel.tokenId,
                        walletIds: [model.userWalletId.stringValue]
                    )
                }

                for model in toUnsubscribe {
                    try await model.priceAlertsSubscriptionsProvider.unsubscribe(
                        tokenId: viewModel.tokenId,
                        walletIds: [model.userWalletId.stringValue]
                    )
                }

                await viewModel.handleApplySuccess()
            } catch {
                await viewModel.presentErrorAlert()
            }
        }
    }
}

// MARK: - Private

private extension PriceAlertsWalletSelectorViewModel {
    func makeWalletItems() {
        // Locked wallets can't manage subscriptions, so they're excluded from the selector. Rows start
        // unselected; the real state is seeded once `loadSubscriptionStates` finishes.
        unlockedModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }

        walletItems = unlockedModels.map { model in
            WalletSelectorItemViewModel(
                userWalletId: model.userWalletId,
                cardSetLabel: model.config.cardSetLabel,
                isUserWalletLocked: model.isUserWalletLocked,
                infoProvider: model,
                totalBalancePublisher: model.totalBalancePublisher,
                isSelected: false,
                didTapWallet: { [weak self] in self?.toggleWallet($0) }
            )
        }
    }

    /// Loads each unlocked wallet's real subscription state so the checkboxes reflect the server — the bell
    /// only ever fetches the selected wallet's provider, leaving the rest unloaded.
    func loadSubscriptionStates() {
        runTask(in: self) { viewModel in
            for model in viewModel.unlockedModels {
                try? await model.priceAlertsSubscriptionsProvider.fetch()
            }

            await viewModel.applyLoadedSubscriptionStates()
        }
    }

    @MainActor
    func applyLoadedSubscriptionStates() {
        let subscribedIds = currentlySubscribedIds()
        initiallySubscribedIds = subscribedIds
        selectedWalletIds = subscribedIds

        for item in walletItems {
            item.isSelected = subscribedIds.contains(item.userWalletId)
        }

        updateSaveEnabled()
    }

    func currentlySubscribedIds() -> Set<UserWalletId> {
        let ids = unlockedModels
            .filter { $0.priceAlertsSubscriptionsProvider.isSubscribed(tokenId: tokenId) }
            .map(\.userWalletId)

        return Set(ids)
    }

    func toggleWallet(_ userWalletId: UserWalletId) {
        if selectedWalletIds.contains(userWalletId) {
            selectedWalletIds.remove(userWalletId)
        } else {
            selectedWalletIds.insert(userWalletId)
        }

        walletItems.first { $0.userWalletId == userWalletId }?.isSelected = selectedWalletIds.contains(userWalletId)
        updateSaveEnabled()
    }

    func updateSaveEnabled() {
        // Save applies the diff, so it's active only when the selection differs from the current state.
        isSaveEnabled = selectedWalletIds != initiallySubscribedIds
    }

    @MainActor
    func handleApplySuccess() {
        // [REDACTED_TODO_COMMENT]
        Toast(view: SuccessToast(text: "Price alerts updated"))
            .present(layout: .top(padding: 14), type: .temporary())

        closeAction()
    }

    @MainActor
    func presentErrorAlert() {
        // [REDACTED_TODO_COMMENT]
        alert = AlertBinder(title: "Something went wrong", message: "Please try again later.")
    }

    /// Offers to open the app's system Settings when push permission is denied (Settings / Cancel).
    @MainActor
    func presentEnablePushSettingsAlert() {
        alert = AlertBuilder.makeEnablePushSettingsAlert(onOpenSettings: {
            UIApplication.openSystemSettings()
        })
    }
}
