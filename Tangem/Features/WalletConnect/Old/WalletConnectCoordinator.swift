//
//  WalletConnectCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class WalletConnectCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var walletConnectViewModel: OldWalletConnectViewModel? = nil

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator? = nil

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WalletConnectCoordinator.Options) {
        walletConnectViewModel = OldWalletConnectViewModel(disabledLocalizedReason: options.disabledLocalizedReason, coordinator: self)
    }
}

extension WalletConnectCoordinator {
    struct Options {
        let disabledLocalizedReason: String?
    }
}

extension WalletConnectCoordinator: WalletConnectRoutable {
    func openQRScanner(with codeBinding: Binding<String>) {
        let coordinator = QRScanViewCoordinator { [weak self] in
            self?.qrScanViewCoordinator = nil
        }

        let options = QRScanViewCoordinator.Options(code: codeBinding, text: "")
        coordinator.start(with: options)
        qrScanViewCoordinator = coordinator
    }
}
