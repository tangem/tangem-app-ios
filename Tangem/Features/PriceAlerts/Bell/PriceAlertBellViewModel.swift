//
//  PriceAlertBellViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import SwiftUI
import TangemFoundation
import TangemUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class PriceAlertBellViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsPermission) private var pushNotificationsPermission: PushNotificationsPermissionService
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published private(set) var isSubscribed: Bool = false
    @Published var alert: AlertBinder?

    private let tokenId: PriceAlertTokenId
    private weak var coordinator: PriceAlertBellRoutable?

    private var provider: PriceAlertsSubscriptionsProvider?
    private var providerSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    init(tokenId: PriceAlertTokenId, coordinator: PriceAlertBellRoutable?) {
        self.tokenId = tokenId
        self.coordinator = coordinator

        bindWalletSelection()
        bindSelectedWalletProvider()
        fetchSubscriptions()
    }

    func toggleTapped() {
        let shouldSubscribe = !isSubscribed
        // Locked wallets can't manage subscriptions (their provider is a throwaway), so the flow
        // operates on unlocked wallets only.
        let unlockedModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }

        // Unsubscribe removes the coin from every unlocked wallet on the device — no wallet choice.
        guard shouldSubscribe else {
            performBellUnsubscription(models: unlockedModels)
            return
        }

        // Several wallets → the user chooses which to subscribe via the Price Alerts sheet.
        if unlockedModels.count > 1 {
            presentPriceAlertsSheet()
            return
        }

        // Single wallet: subscribe the selected wallet directly.
        performBellSubscription(walletIds: currentWalletIds())
    }
}

// MARK: - Private

private extension PriceAlertBellViewModel {
    func bindWalletSelection() {
        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { viewModel, event in
                guard case .selected = event else {
                    return
                }

                viewModel.bindSelectedWalletProvider()
                viewModel.fetchSubscriptions()
            }
            .store(in: &bag)
    }

    func bindSelectedWalletProvider() {
        provider = userWalletRepository.selectedModel?.priceAlertsSubscriptionsProvider

        providerSubscription = provider?.subscriptionsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, subscriptions in
                viewModel.isSubscribed = subscriptions.isSubscribed(tokenId: viewModel.tokenId)
            }
    }

    func fetchSubscriptions() {
        runTask(in: self) { viewModel in
            try? await viewModel.provider?.fetch()
        }
    }

    func presentPriceAlertsSheet() {
        runTask(in: self) { viewModel in
            guard await viewModel.pushNotificationsPermission.ensureAuthorized() else {
                await viewModel.presentEnablePushSettingsAlert()
                return
            }

            await viewModel.enqueuePriceAlertsSheet()
        }
    }

    @MainActor
    func enqueuePriceAlertsSheet() {
        floatingSheetPresenter.enqueue(sheet: PriceAlertsViewModel(tokenId: tokenId))
    }

    // [REDACTED_TODO_COMMENT]
    // notification-preferences on subscribe. Deferred: the bell only manages the subscription here.
    func performBellSubscription(walletIds: [String]) {
        guard let provider else {
            return
        }

        runTask(in: self) { viewModel in
            guard await viewModel.pushNotificationsPermission.ensureAuthorized() else {
                // Permission declined/denied — offer to open system Settings (mirrors PushSettings).
                await viewModel.presentEnablePushSettingsAlert()
                return
            }

            do {
                try await provider.subscribe(tokenId: viewModel.tokenId, walletIds: walletIds)
                await viewModel.presentConfirmationToast(isSubscribed: true)
            } catch {
                // The provider already rolled the optimistic flip back; just surface the error.
                await viewModel.presentErrorAlert()
            }
        }
    }

    /// Unsubscribe fans out across each unlocked wallet's own provider so every wallet's cached bell
    /// state updates, mirroring the subscribe fan-out in the Choose wallet sheet.
    func performBellUnsubscription(models: [UserWalletModel]) {
        guard !models.isEmpty else {
            return
        }

        runTask(in: self) { viewModel in
            do {
                for model in models {
                    try await model.priceAlertsSubscriptionsProvider.unsubscribe(
                        tokenId: viewModel.tokenId,
                        walletIds: [model.userWalletId.stringValue]
                    )
                }

                await viewModel.presentConfirmationToast(isSubscribed: false)
            } catch {
                await viewModel.presentErrorAlert()
            }
        }
    }

    func currentWalletIds() -> [String] {
        guard let walletId = userWalletRepository.selectedModel?.userWalletId.stringValue else {
            return []
        }

        return [walletId]
    }

    @MainActor
    func presentConfirmationToast(isSubscribed: Bool) {
        // [REDACTED_TODO_COMMENT]
        let text = isSubscribed ? "Token added to price alert" : "Token removed from price alert"
        Toast(view: SuccessToast(text: text))
            .present(layout: .top(padding: 14), type: .temporary())
    }

    @MainActor
    func presentErrorAlert() {
        // [REDACTED_TODO_COMMENT]
        alert = AlertBinder(title: "Something went wrong", message: "Please try again later.")
    }

    /// Offers to open the app's system Settings when push permission is denied (Settings / Cancel).
    @MainActor
    func presentEnablePushSettingsAlert() {
        alert = AlertBuilder.makeEnablePushSettingsAlert(onOpenSettings: { [weak self] in
            self?.coordinator?.openAppSettings()
        })
    }
}
