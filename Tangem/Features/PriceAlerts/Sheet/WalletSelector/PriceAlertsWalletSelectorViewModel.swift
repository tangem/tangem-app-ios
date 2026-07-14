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
    @Published private(set) var isAddEnabled: Bool = true
    @Published var alert: AlertBinder?

    private let tokenId: PriceAlertTokenId
    private let closeAction: () -> Void
    private var selectedWalletIds: Set<UserWalletId> = []

    init(tokenId: PriceAlertTokenId, closeAction: @escaping () -> Void) {
        self.tokenId = tokenId
        self.closeAction = closeAction
        makeWalletItems()
    }

    func closeTapped() {
        closeAction()
    }

    func addToPriceAlertTapped() {
        let selectedModels = userWalletRepository.models.filter { selectedWalletIds.contains($0.userWalletId) }
        guard !selectedModels.isEmpty else {
            return
        }

        runTask(in: self) { viewModel in
            // Push authorization is verified before the sheet opens, but the user may have revoked it
            // meanwhile — re-check before subscribing so we never create alerts that can't be delivered.
            guard await viewModel.pushNotificationsPermission.ensureAuthorized() else {
                await viewModel.presentEnablePushSettingsAlert()
                return
            }

            do {
                // Fan-out via each wallet's own provider so its optimistic state stays correct.
                // A single atomic POST with all walletIds is deferred to the final BE contract (OQ-1).
                for model in selectedModels {
                    try await model.priceAlertsSubscriptionsProvider.subscribe(
                        tokenId: viewModel.tokenId,
                        walletIds: [model.userWalletId.stringValue]
                    )
                }

                await viewModel.handleSubscribeSuccess()
            } catch {
                await viewModel.presentErrorAlert()
            }
        }
    }
}

// MARK: - Private

private extension PriceAlertsWalletSelectorViewModel {
    func makeWalletItems() {
        // Locked wallets can't manage subscriptions, so they're excluded from the selector.
        let models = userWalletRepository.models.filter { !$0.isUserWalletLocked }
        selectedWalletIds = Set(models.map(\.userWalletId))

        walletItems = models.map { model in
            WalletSelectorItemViewModel(
                userWalletId: model.userWalletId,
                cardSetLabel: model.config.cardSetLabel,
                isUserWalletLocked: model.isUserWalletLocked,
                infoProvider: model,
                totalBalancePublisher: model.totalBalancePublisher,
                isSelected: true,
                didTapWallet: { [weak self] in self?.toggleWallet($0) }
            )
        }

        updateAddEnabled()
    }

    func toggleWallet(_ userWalletId: UserWalletId) {
        if selectedWalletIds.contains(userWalletId) {
            selectedWalletIds.remove(userWalletId)
        } else {
            selectedWalletIds.insert(userWalletId)
        }

        walletItems.first { $0.userWalletId == userWalletId }?.isSelected = selectedWalletIds.contains(userWalletId)
        updateAddEnabled()
    }

    func updateAddEnabled() {
        isAddEnabled = !selectedWalletIds.isEmpty
    }

    @MainActor
    func handleSubscribeSuccess() {
        // [REDACTED_TODO_COMMENT]
        Toast(view: SuccessToast(text: "Token added to price alert"))
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
