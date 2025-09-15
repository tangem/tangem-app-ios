//
//  PushNotificationsPermissionRequestViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class PushNotificationsPermissionRequestViewModel: ObservableObject, Identifiable {
    @Published private(set) var allowButtonTitle: String
    @Published private(set) var laterButtonTitle: String

    let isPushTransactionsAvailable: Bool

    private let permissionManager: PushNotificationsPermissionManager

    private weak var delegate: PushNotificationsPermissionRequestDelegate?
    private var requestResult: PermissionRequestResult = .noInteraction

    init(
        permissionManager: PushNotificationsPermissionManager,
        delegate: PushNotificationsPermissionRequestDelegate
    ) {
        self.permissionManager = permissionManager
        self.delegate = delegate

        allowButtonTitle = Localization.commonAllow
        laterButtonTitle = Localization.commonLater

        isPushTransactionsAvailable = FeatureProvider.isAvailable(.pushTransactionNotifications)
    }

    func onViewAppear() {
        permissionManager.logPushNotificationScreenOpened()
    }

    func didTapAllow() {
        requestResult = .allow
        delegate?.didFinishPushNotificationOnboarding()
    }

    func didTapLater() {
        requestResult = .later
        delegate?.didFinishPushNotificationOnboarding()
    }

    func didDismissSheet() {
        switch requestResult {
        case .allow:
            runTask(in: self) { viewModel in
                await viewModel.permissionManager.allowPermissionRequest()
            }
        case .later, .noInteraction:
            permissionManager.postponePermissionRequest()
        }
    }
}

extension PushNotificationsPermissionRequestViewModel {
    enum PermissionRequestResult {
        case allow
        case later
        case noInteraction
    }
}
