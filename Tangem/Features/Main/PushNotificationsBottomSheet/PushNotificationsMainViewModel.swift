//
//  PushNotificationsMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
final class PushNotificationsMainViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.experimentService) private var experimentService: ExperimentService

    // MARK: - View State

    @Published private(set) var viewState: ViewState?

    // MARK: - Dependencies

    private let permissionManager: PushNotificationsPermissionManager
    private let walletId: String?

    private lazy var permissionRequestViewModel = PushNotificationsPermissionRequestViewModel(
        permissionManager: permissionManager,
        delegate: self
    )

    private var isWarningViewAvailable: Bool {
        FeatureProvider.isAvailable(.mainPushNotificationDoubleAsk)
            && experimentService.isOn(.mainPushNotificationDoubleAsk)
    }

    private lazy var warningViewModel = PushNotificationsWarningViewModel(
        permissionManager: permissionManager,
        analyticsContext: PushNotificationsWarningAnalyticsContext(
            zone: .main,
            variant: isWarningViewAvailable ? .treatment : .control,
            walletId: walletId
        ),
        dismissAction: { [weak self] in
            self?.dismiss()
        }
    )

    init(permissionManager: PushNotificationsPermissionManager, walletId: String?) {
        self.permissionManager = permissionManager
        self.walletId = walletId
    }

    func start() {
        viewState = .onboarding(viewModel: permissionRequestViewModel)
    }

    /// Preserves the «postpone on no interaction» logging when the sheet is dismissed by a swipe or a tap outside.
    func onDismiss() {
        permissionRequestViewModel.didDismissSheet()
    }

    private func dismiss() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension PushNotificationsMainViewModel: @MainActor PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        dismiss()
    }

    func didPostponePushNotifications() {
        guard isWarningViewAvailable else {
            dismiss()
            return
        }

        viewState = .warning(viewModel: warningViewModel)
    }
}

// MARK: - FloatingSheetContentViewModel

extension PushNotificationsMainViewModel: FloatingSheetContentViewModel {}

// MARK: - ViewState

extension PushNotificationsMainViewModel {
    enum ViewState: Identifiable, Equatable {
        case onboarding(viewModel: PushNotificationsPermissionRequestViewModel)
        case warning(viewModel: PushNotificationsWarningViewModel)

        var id: String {
            switch self {
            case .onboarding:
                "onboarding"
            case .warning:
                "warning"
            }
        }

        static func == (lhs: PushNotificationsMainViewModel.ViewState, rhs: PushNotificationsMainViewModel.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.onboarding, .onboarding):
                return true
            case (.warning, .warning):
                return true
            default:
                return false
            }
        }
    }
}
