//
//  PushNotificationsWarningViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import protocol TangemUI.FloatingSheetContentViewModel
import TangemLocalization

final class PushNotificationsWarningViewModel: ObservableObject {
    @Published private(set) var isRequestingPermission = false

    private let permissionManager: PushNotificationsPermissionManager
    private let analyticsContext: PushNotificationsWarningAnalyticsContext
    private let dismissAction: () -> Void

    init(
        permissionManager: PushNotificationsPermissionManager,
        analyticsContext: PushNotificationsWarningAnalyticsContext,
        dismissAction: @escaping () -> Void
    ) {
        self.permissionManager = permissionManager
        self.analyticsContext = analyticsContext
        self.dismissAction = dismissAction
    }
}

// MARK: - Internal methods

extension PushNotificationsWarningViewModel {
    func onViewAppear() {
        Analytics.log(event: .warningScreenShown, params: analyticsContext.params)
    }

    func onCloseTap() {
        Analytics.log(event: .warningScreenSkipTapped, params: analyticsContext.params)
        dismissAction()
    }

    func onSkipTap() {
        Analytics.log(event: .warningScreenSkipTapped, params: analyticsContext.params)
        dismissAction()
    }

    func onEnableTap() {
        guard !isRequestingPermission else { return }

        Analytics.log(event: .warningScreenEnableTapped, params: analyticsContext.params)

        isRequestingPermission = true

        runTask(in: self) { viewModel in
            await viewModel.permissionManager.allowPermissionRequest()

            await runOnMain {
                viewModel.isRequestingPermission = false
                viewModel.dismissAction()
            }
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension PushNotificationsWarningViewModel: FloatingSheetContentViewModel {}
