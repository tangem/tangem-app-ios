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
    var dismissAction: () -> Void = {}
    var popToRootAction: (PopToRootOptions) -> Void = { _ in }
    
    //MARK: - Main view model
    @Published private(set) var walletConnectViewModel: WalletConnectViewModel? = nil
    
    
    //MARK: - Child view models
    @Published var qrScanViewModel: QRScanViewModel? = nil
    
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
