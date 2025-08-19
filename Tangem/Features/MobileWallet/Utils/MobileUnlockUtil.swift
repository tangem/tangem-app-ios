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

    private let userWalletId: UserWalletId
    private let config: UserWalletConfig
    private let biometricsProvider: UserWalletBiometricsProvider

    init(userWalletId: UserWalletId, config: UserWalletConfig, biometricsProvider: UserWalletBiometricsProvider) {
        self.userWalletId = userWalletId
        self.config = config
        self.biometricsProvider = biometricsProvider
    }
}

// MARK: - Internal methods

extension MobileUnlockUtil {
    func unlock() async throws -> Result {
        let manager = await CommonMobileAccessCodeManager(
            userWalletId: userWalletId,
            configuration: .default,
            storageManager: CommonMobileAccessCodeStorageManager()
        )

        let viewModel = MobileUnlockViewModel(userWalletId: userWalletId, accessCodeManager: manager)
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
            return .canceled

        case .unavailableDueToDeletion:
            await dismissAccessCode()
            return .userWalletNeedsToDelete
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
