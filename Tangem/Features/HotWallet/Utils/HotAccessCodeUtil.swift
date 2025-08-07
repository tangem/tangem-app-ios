//
//  HotAccessCodeUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TangemFoundation
import TangemHotSdk
import class TangemSdk.BiometricsUtil

final class HotAccessCodeUtil {
    private lazy var hotSdk: HotSdk = CommonHotSdk()

    private var isAccessCodeSet: Bool {
        !config.hasFeature(.userWalletAccessCode)
    }

    private var isAccessCodeRequired: Bool {
        // [REDACTED_TODO_COMMENT]
        !AppSettings.shared.saveUserWallets
    }

    private var isBiometricsEnabled: Bool {
        // [REDACTED_TODO_COMMENT]
        true
    }

    private var presentedAccessCodeController: UIViewController?

    private let userWalletId: UserWalletId
    private let config: UserWalletConfig

    init(userWalletId: UserWalletId, config: UserWalletConfig) {
        self.userWalletId = userWalletId
        self.config = config
    }
}

// MARK: - Internal methods

extension HotAccessCodeUtil {
    func unlock(method: UnlockMethod) async throws -> Result {
        // If access code is not set - user wallet is unprotected.
        guard isAccessCodeSet else {
            let context = try hotSdk.validate(auth: .none, for: userWalletId)
            return .accessCode(context)
        }

        switch method {
        case .default(let useBiometrics):
            if isAccessCodeRequired {
                return try await unlock(useBiometrics: useBiometrics)
            }

            if BiometricsUtil.isAvailable, isBiometricsEnabled {
                return .biometricsRequired
            } else {
                return try await unlock(useBiometrics: useBiometrics)
            }

        case .manual(let useBiometrics):
            return try await unlock(useBiometrics: useBiometrics)
        }
    }
}

// MARK: - Unlocking

private extension HotAccessCodeUtil {
    func unlock(useBiometrics: Bool) async throws -> Result {
        do {
            let manager = CommonHotAccessCodeManager(userWalletId: userWalletId, configuration: .default)
            let viewModel = HotAccessCodeViewModel(manager: manager, useBiometrics: useBiometrics)
            let view = HotAccessCodeView(viewModel: viewModel)

            await presentAcessCode(view: view)
            let accessCodeResult = try await viewModel.resultPublisher.async()
            await dismissAccessCode()
            return makeUnlockResult(from: accessCodeResult)

        } catch {
            await dismissAccessCode()
            throw error
        }
    }
}

// MARK: - Mapping

private extension HotAccessCodeUtil {
    func makeUnlockResult(from result: HotAccessCodeResult) -> Result {
        switch result {
        case .accessCodeSuccessfull(let context):
            return .accessCode(context)
        case .biometricsRequest:
            return .biometricsRequired
        case .closed, .dismissed:
            return .canceled
        case .unavailableDueToDeletion:
            return .userWalletNeedsToDelete
        }
    }
}

// MARK: - Presentation

@MainActor
private extension HotAccessCodeUtil {
    func presentAcessCode<T: View>(view: T) {
        let hostingVC = UIHostingController(rootView: view)
        presentedAccessCodeController = hostingVC
        AppPresenter.shared.show(hostingVC)
    }

    func dismissAccessCode() {
        presentedAccessCodeController?.dismiss(
            animated: true,
            completion: { [weak self] in
                self?.presentedAccessCodeController = nil
            }
        )
    }
}

// MARK: - Types

extension HotAccessCodeUtil {
    enum UnlockMethod {
        case `default`(useBiometrics: Bool)
        case manual(useBiometrics: Bool)
    }

    enum Result {
        /// Mobile wallet context received after successful access code entry.
        case accessCode(MobileWalletContext)
        /// Biometric authentication is required to proceed.
        case biometricsRequired
        /// Authorization was canceled by the user.
        case canceled
        /// Wallet needs to be deleted.
        case userWalletNeedsToDelete
    }
}
