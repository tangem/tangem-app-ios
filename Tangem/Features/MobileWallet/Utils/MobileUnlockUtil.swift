//
//  MobileUnlockUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import LocalAuthentication
import TangemFoundation
import TangemMobileWalletSdk
import class TangemSdk.BiometricsUtil

final class MobileUnlockUtil {
    private var presentedAccessCodeController: UIViewController?

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletId: UserWalletId
    private let config: UserWalletConfig
    private let biometricsProvider: UserWalletBiometricsProvider
    private let accessCodeManager: MobileAccessCodeManager

    init(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        biometricsProvider: UserWalletBiometricsProvider,
        accessCodeManager: MobileAccessCodeManager,
    ) {
        self.userWalletId = userWalletId
        self.config = config
        self.biometricsProvider = biometricsProvider
        self.accessCodeManager = accessCodeManager
    }
}

// MARK: - Internal methods

extension MobileUnlockUtil {
    func unlock() async throws -> Result {
        let viewModel = MobileUnlockViewModel(userWalletId: userWalletId, accessCodeManager: accessCodeManager)
        let view = MobileUnlockView(viewModel: viewModel)
        await presentAccessCode(view: view)

        return try await viewModel.actionPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .asyncMap { util, action -> Result? in
                await util.handleAction(action)
            }
            .compactMap { $0 }
            .async()
    }
}

// MARK: - Private methods

private extension MobileUnlockUtil {
    func handleAction(_ action: MobileUnlockViewModel.Action) async -> Result? {
        switch action {
        case .accessCodeSuccessful(let context):
            refreshBiometricsIfNeeded(context: context)
            await dismissAccessCode()
            return .accessCode(context)

        case .biometricsRequest:
            do {
                let context = try await biometricsProvider.unlock()
                await dismissAccessCode()
                return .biometrics(context)
            } catch {
                AppLogger.error("Mobile accessCodeUtil failed to unlock with biometrics", error: error)
                return nil
            }

        case .closed:
            await dismissAccessCode()
            return .canceled

        case .dismissed:
            await notifyUnlockFinish()
            return .canceled

        case .unavailableDueToDeletion:
            await dismissAccessCode()
            return .userWalletNeedsToDelete
        }
    }

    func refreshBiometricsIfNeeded(context: MobileWalletContext) {
        if BiometricsUtil.isAvailable,
           AppSettings.shared.useBiometricAuthentication,
           !AppSettings.shared.requireAccessCodes,
           !mobileWalletSdk.isBiometricsEnabled(for: userWalletId) {
            try? mobileWalletSdk.refreshBiometrics(context: context)
        }
    }
}

// MARK: - Presentation

@MainActor
private extension MobileUnlockUtil {
    func presentAccessCode<T: View>(view: T) {
        let hostingVC = UIHostingController(rootView: view)
        presentedAccessCodeController = hostingVC
        AppPresenter.shared.show(hostingVC)
        notifyUnlockStart()
    }

    func dismissAccessCode() {
        presentedAccessCodeController?.dismiss(
            animated: true,
            completion: { [weak self] in
                self?.presentedAccessCodeController = nil
            }
        )
        notifyUnlockFinish()
    }

    func notifyUnlockStart() {
        NotificationCenter.default.post(name: .mobileUnlockDidStart, object: self)
    }

    func notifyUnlockFinish() {
        NotificationCenter.default.post(name: .mobileUnlockDidFinish, object: self)
    }
}

// MARK: - Types

extension MobileUnlockUtil {
    enum Result {
        /// Mobile wallet context received after successful access code entry.
        case accessCode(MobileWalletContext)
        /// Biometric context received after successful challenge.
        case biometrics(LAContext)
        /// Authorization was canceled by the user.
        case canceled
        /// Wallet needs to be deleted.
        case userWalletNeedsToDelete
    }
}
