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
        // With several wallets the user picks which ones to (un)subscribe via the Price Alerts sheet;
        // with a single wallet we act on it directly.
        if userWalletRepository.models.count > 1 {
            let sheetViewModel = PriceAlertsViewModel(tokenId: tokenId)

            Task { @MainActor in
                floatingSheetPresenter.enqueue(sheet: sheetViewModel)
            }

            return
        }

        guard
            let provider,
            let selectedWalletId = userWalletRepository.selectedModel?.userWalletId.stringValue
        else {
            return
        }

        let shouldSubscribe = !isSubscribed
        // Unsubscribe removes the coin from every wallet on the device
        let deviceWalletIds = userWalletRepository.models.map(\.userWalletId.stringValue)

        // [REDACTED_TODO_COMMENT]
        // notification-preferences on subscribe. Deferred: the bell only manages the subscription here.
        runTask(in: self) { viewModel in
            if shouldSubscribe {
                let isAuthorized = await viewModel.ensurePushAuthorization()
                guard isAuthorized else {
                    // Permission declined/denied — offer to open system Settings (mirrors PushSettings).
                    await viewModel.presentEnablePushSettingsAlert()
                    return
                }
            }

            do {
                if shouldSubscribe {
                    try await provider.subscribe(tokenId: viewModel.tokenId, walletIds: [selectedWalletId])
                } else {
                    try await provider.unsubscribe(tokenId: viewModel.tokenId, walletIds: deviceWalletIds)
                }

                await viewModel.presentConfirmationToast(isSubscribed: shouldSubscribe)
            } catch {
                // The provider already rolled the optimistic flip back; just surface the error.
                await viewModel.presentErrorAlert()
            }
        }
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

    /// Returns whether push notifications are authorized. When permission hasn't been determined yet,
    /// `requestAuthorizationAndRegister()` shows the system prompt; when already denied it's a no-op, and
    /// the caller falls back to the "open Settings" alert. Mirrors the NotificationSettings flow.
    func ensurePushAuthorization() async -> Bool {
        if await pushNotificationsPermission.isAuthorized {
            return true
        }

        await pushNotificationsPermission.requestAuthorizationAndRegister()
        return await pushNotificationsPermission.isAuthorized
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

    /// Offers to open the app's system Settings when push permission is denied (Settings / Cancel),
    /// reusing the existing push-permission alert strings. Mirrors NotificationSettings.
    @MainActor
    func presentEnablePushSettingsAlert() {
        let buttons = AlertBuilder.Buttons(
            primaryButton: .default(Text(Localization.pushNotificationsPermissionAlertNegativeButton)),
            secondaryButton: .default(Text(Localization.pushNotificationsPermissionAlertPositiveButton)) { [weak self] in
                self?.coordinator?.openAppSettings()
            }
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.pushNotificationsPermissionAlertTitle,
            message: Localization.pushNotificationsPermissionAlertDescription,
            with: buttons
        )
    }
}
