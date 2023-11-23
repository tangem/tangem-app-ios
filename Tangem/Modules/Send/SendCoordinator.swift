//
//  SendCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk

class SendCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    @Published var qrScanViewModel: QRScanViewModel? = nil

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = SendViewModel(
            walletModel: options.walletModel,
            transactionSigner: options.transactionSigner,
            sendType: options.type,
            coordinator: self
        )
    }
}

// MARK: - Options

extension SendCoordinator {
    struct Options {
        let walletModel: WalletModel
        let transactionSigner: TransactionSigner
        let type: SendType
    }
}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func openQRScanner(with codeBinding: Binding<String>) {
        qrScanViewModel = .init(code: codeBinding)
    }
}
