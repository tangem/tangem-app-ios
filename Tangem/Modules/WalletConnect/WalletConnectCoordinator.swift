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
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model
    @Published private(set) var walletConnectViewModel: WalletConnectViewModel? = nil

    // MARK: - Child view models
    @Published var qrScanViewModel: QRScanViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: WalletConnectCoordinator.Options) {
        walletConnectViewModel = WalletConnectViewModel(cardModel: options.cardModel, coordinator: self)
    }
}

extension WalletConnectCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

extension WalletConnectCoordinator: WalletConnectRoutable {
    func openQRScanner(with codeBinding: Binding<String>) {
        qrScanViewModel = .init(code: codeBinding)
    }
}
