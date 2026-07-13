//
//  NotificationSettingsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class NotificationSettingsViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.pushNotificationsPermission) private var pushNotificationsPermission: PushNotificationsPermissionService

    // MARK: - ViewState

    @Published private(set) var viewState: ViewState = .loading
    @Published private(set) var isRetryButtonBusy: Bool = false

    @Published private(set) var allowNotificationsBannerInput: NotificationViewInput?

    @Published var transactionAlertsEnabled: Bool = false
    @Published var offersUpdatesEnabled: Bool = false
    @Published var priceAlertsEnabled: Bool = false

    @Published private(set) var transactionAlertsViewModel: DefaultToggleRowViewModel?
    @Published private(set) var offersUpdatesViewModel: DefaultToggleRowViewModel?
    @Published private(set) var priceAlertsViewModel: DefaultToggleRowViewModel?
    @Published private(set) var priceAlertsRowViewModel: DefaultRowViewModel?

    @Published var alert: AlertBinder?

    // MARK: - Private

    private let userWalletModel: UserWalletModel
    private weak var coordinator: NotificationSettingsRoutable?

    private var userWalletPushNotificationsManager: UserWalletPushNotificationsManager

    private var isEnabledTransactionAlertsBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.transactionAlertsEnabled },
            set: { viewModel, value in
                viewModel.transactionAlertsEnabled = value
                viewModel.handleToggle(value: value, for: .transactionAlerts)
            }
        )
    }

    private var isEnabledOffersUpdatesBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.offersUpdatesEnabled },
            set: { viewModel, value in
                viewModel.offersUpdatesEnabled = value
                viewModel.handleToggle(value: value, for: .offersUpdates)
            }
        )
    }

    private var isEnabledPriceAlertsEnabledBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.priceAlertsEnabled },
            set: { viewModel, value in
                viewModel.priceAlertsEnabled = value
                viewModel.handleToggle(value: value, for: .priceAlerts)
            }
        )
    }

    private var bannerActionTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?

    /// Shared push-settings toggle flow (pending enable + system-permission handling).
    private lazy var toggleInteractor = PushChannelToggleInteractor(
        userWalletPushNotificationsManager: userWalletPushNotificationsManager,
        output: self
    )

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(userWalletModel: UserWalletModel, coordinator: NotificationSettingsRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        userWalletPushNotificationsManager = userWalletModel.userWalletPushNotificationsManager

        setupViewModels()
        bind()
    }

    // MARK: - Lifecycle

    func onAppear() {
        toggleInteractor.refreshSystemPermissionState()
        logScreenOpened()
    }

    func onTapMoreInfoTransactionPushNotifications() {
        coordinator?.openTransactionNotifications()
    }

    var isPriceAlertsScreenAvailable: Bool {
        FeatureProvider.isAvailable(.priceAlertsSubscription)
    }

    func onTapPriceAlerts() {
        coordinator?.openPriceAlerts(with: userWalletModel)
    }

    /// Retries the preferences load from the error state. Screen state transitions are driven
    /// reactively by `preferencesPublisher`; this only tracks the retry button busy indicator.
    func onRetryLoadPreferencesTap() {
        guard !isRetryButtonBusy else {
            return
        }

        isRetryButtonBusy = true

        retryTask?.cancel()
        retryTask = runTask(in: self) { @MainActor viewModel in
            defer { viewModel.isRetryButtonBusy = false }
            try? await viewModel.userWalletPushNotificationsManager.refetchPreferences()
        }
    }
}

// MARK: - Types

extension NotificationSettingsViewModel {
    enum ViewState {
        case loading
        case content
        case error
    }
}

// MARK: - Private

private extension NotificationSettingsViewModel {
    func bind() {
        // The interactor owns the system permission flag (primed from `onAppear` and refreshed on
        // `didBecomeActive`); it drives the toggle disabled state.
        toggleInteractor.isSystemPermissionGrantedPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.rebuildToggleViewModels()
            }
            .store(in: &bag)

        // The banner offers to grant a permission we actually need, so it only makes sense when the
        // system permission is missing AND at least one channel is enabled. With everything OFF there
        // is nothing to allow, hence no banner. Driven by both the permission flag and the toggles.
        Publishers.CombineLatest4(
            toggleInteractor.isSystemPermissionGrantedPublisher,
            $transactionAlertsEnabled,
            $offersUpdatesEnabled,
            $priceAlertsEnabled
        )
        .map { isAuthorized, transactionAlerts, offersUpdates, priceAlerts in
            !isAuthorized && (transactionAlerts || offersUpdates || priceAlerts)
        }
        .removeDuplicates()
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { viewModel, shouldShowBanner in
            viewModel.allowNotificationsBannerInput = shouldShowBanner ? viewModel.makeAllowNotificationsBannerInput() : nil
        }
        .store(in: &bag)

        userWalletPushNotificationsManager
            .preferencesPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, preferences in
                viewModel.applyPreferences(preferences)
            }
            .store(in: &bag)
    }

    func setupViewModels() {
        rebuildToggleViewModels()
    }

    func rebuildToggleViewModels() {
        transactionAlertsViewModel = DefaultToggleRowViewModel(
            title: Localization.pushTransactionsNotificationsTitle,
            isOn: isEnabledTransactionAlertsBinding
        )

        offersUpdatesViewModel = DefaultToggleRowViewModel(
            title: Localization.pushNotificationSettingsOffersUpdatesTitle,
            isOn: isEnabledOffersUpdatesBinding
        )

        rebuildPriceAlertsViewModel()
    }

    /// With the Price Alerts feature on, the consent toggle moves onto a dedicated screen ([REDACTED_INFO])
    /// and this becomes a navigation row showing the current On/Off state. Otherwise it stays a toggle.
    func rebuildPriceAlertsViewModel() {
        guard isPriceAlertsScreenAvailable else {
            priceAlertsRowViewModel = nil
            priceAlertsViewModel = DefaultToggleRowViewModel(
                title: Localization.pushNotificationSettingsPriceAlertsTitle,
                isOn: isEnabledPriceAlertsEnabledBinding
            )
            return
        }

        priceAlertsViewModel = nil
        priceAlertsRowViewModel = DefaultRowViewModel(
            title: Localization.pushNotificationSettingsPriceAlertsTitle,
            detailsType: .text(priceAlertsDetailText),
            action: weakify(self, forFunction: NotificationSettingsViewModel.onTapPriceAlerts)
        )
    }

    var priceAlertsDetailText: String {
        // [REDACTED_TODO_COMMENT]
        priceAlertsEnabled ? "On" : "Off"
    }

    func applyPreferences(_ preferences: RemotePushPreferences) {
        switch preferences.state {
        case .loading:
            viewState = .loading
        case .failed:
            viewState = .error
        case .ready:
            transactionAlertsEnabled = preferences.preference(for: .transactionAlerts).isEnabled
            offersUpdatesEnabled = preferences.preference(for: .offersUpdates).isEnabled
            priceAlertsEnabled = preferences.preference(for: .priceAlerts).isEnabled
            priceAlertsRowViewModel?.update(detailsType: .text(priceAlertsDetailText))
            viewState = .content
        }
    }

    func makeAllowNotificationsBannerInput() -> NotificationViewInput {
        let buttonAction: NotificationView.NotificationButtonTapAction = { [weak self] _, _ in
            self?.handleBannerOpenSettingsTap()
        }

        return NotificationViewInput(
            style: .withButtons([
                NotificationView.NotificationButton(
                    action: buttonAction,
                    actionType: .openPushNotificationsSystemSettings,
                    isWithLoader: false
                ),
            ]),
            severity: .warning,
            settings: .init(event: PushSettingsNotificationsEvent.allowNotifications, dismissAction: nil)
        )
    }
}

// MARK: - Channel Toggle Handling

private extension NotificationSettingsViewModel {
    /// Optimistically updates the UI (via the binding setter), then delegates the permission-aware
    /// channel update to `PushChannelToggleInteractor`. On failure the `preferencesPublisher`
    /// subscription rolls back the toggle automatically and the interactor reports back through
    /// the output.
    func handleToggle(value: Bool, for channel: PushChannel) {
        Analytics.log(
            event: .pushNotificationSettingsToggleClicked,
            params: [
                .toggleType: analyticsToggleType(for: channel),
                .state: Analytics.ParameterValue.toggleState(for: value).rawValue,
            ]
        )

        toggleInteractor.toggle(value, for: channel)
    }
}

// MARK: - Banner Action

private extension NotificationSettingsViewModel {
    /// Handles the «Open Settings» tap on the allow-notifications banner:
    /// 1. Requests system authorization (shows the iOS prompt if not yet decided).
    /// 2. If authorization is still denied after the prompt, opens the app's system Settings page.
    /// 3. No toggles are flipped — the interactor's permission pipeline reacts automatically
    ///    when the user returns from Settings via `isAuthorizedPublisher`.
    func handleBannerOpenSettingsTap() {
        logBannerOpenSettingsTapped()

        bannerActionTask?.cancel()

        bannerActionTask = runTask(in: self) { @MainActor viewModel in
            // The awaits below aren't cooperatively cancellable; guard explicitly so a superseding
            // tap doesn't let a resumed continuation open Settings or refresh state out of order.
            await viewModel.pushNotificationsPermission.requestAuthorizationAndRegister()
            guard !Task.isCancelled else { return }

            let isAuthorized = await viewModel.pushNotificationsPermission.isAuthorized
            guard !Task.isCancelled else { return }

            if !isAuthorized {
                viewModel.coordinator?.openAppSettings()
            }

            viewModel.toggleInteractor.refreshSystemPermissionState()
        }
    }
}

// MARK: - PushChannelToggleInteractorOutput

extension NotificationSettingsViewModel: PushChannelToggleInteractorOutput {
    func revertToggle(for channel: PushChannel) {
        switch channel {
        case .transactionAlerts: transactionAlertsEnabled = false
        case .offersUpdates: offersUpdatesEnabled = false
        case .priceAlerts: priceAlertsEnabled = false
        }
    }

    func presentEnablePushSettingsAlert(for channel: PushChannel) {
        alert = AlertBuilder.makeEnablePushSettingsAlert(
            onCancel: { [weak self] in
                self?.toggleInteractor.cancelPendingEnable(for: channel)
                self?.revertToggle(for: channel)
                self?.coordinator?.onAlertDismiss()
            },
            onOpenSettings: { [weak self] in
                self?.coordinator?.openAppSettings()
                self?.coordinator?.onAlertDismiss()
            }
        )
    }

    func handlePreferenceUpdateFailure(for channel: PushChannel) {
        alert = AlertBinder(
            title: Localization.commonError,
            message: Localization.commonSomethingWentWrong
        )
    }
}

// MARK: - Analytics

private extension NotificationSettingsViewModel {
    func analyticsToggleType(for channel: PushChannel) -> String {
        switch channel {
        case .transactionAlerts: "transaction_alerts"
        case .offersUpdates: "offers_updates"
        case .priceAlerts: "price_alerts"
        }
    }

    func logScreenOpened() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let isAuthorized = await pushNotificationsPermission.isAuthorized
            Analytics.log(
                .notificationSettingsScreenOpened,
                params: [.state: .boolState(for: isAuthorized)]
            )
        }
    }

    func logBannerOpenSettingsTapped() {
        Analytics.log(.pushBannerOpenSettingsTapped)
    }
}
