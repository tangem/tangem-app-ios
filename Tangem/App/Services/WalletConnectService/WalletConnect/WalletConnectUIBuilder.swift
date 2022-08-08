//
//  WalletConnectUIBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WalletConnectEvent {
    case establishSession
    case sign
    case sendTx
    case error
    case success

    var withCancelButton: Bool {
        switch self {
        case .error, .success: return false
        default: return true
        }
    }
}

enum WalletConnectUIBuilder {
    static func makeAlert(for event: WalletConnectEvent,
                          message: String,
                          onAcceptAction: @escaping () -> Void = {},
                          isAcceptEnabled: Bool = true,
                          onReject: @escaping () -> Void = {},
                          extraTitle: String? = nil,
                          onExtra: @escaping () -> Void = {}) -> UIAlertController {
        let vc: UIAlertController = UIAlertController(title: "WalletConnect", message: message, preferredStyle: .alert)
        let buttonTitle: String

        switch event {
        case .establishSession:
            buttonTitle = "common_start".localized
        case .sign:
            buttonTitle = "common_sign".localized
        case .sendTx:
            buttonTitle = "common_sign_and_send".localized
        case .error, .success:
            buttonTitle = "common_ok".localized
        }

        if event.withCancelButton {
            vc.addAction(UIAlertAction(title: "common_reject".localized, style: .cancel, handler: { _ in onReject() }))
        }

        if let extraTitle = extraTitle {
            vc.addAction(UIAlertAction(title: extraTitle, style: .default, handler: { _ in onExtra() }))
        }

        let acceptButton = UIAlertAction(title: buttonTitle, style: .default, handler: { _ in onAcceptAction() })
        acceptButton.isEnabled = isAcceptEnabled
        vc.addAction(acceptButton)
        return vc
    }

    static func makeErrorAlert(_ error: Error) -> UIAlertController {
        makeAlert(for: .error, message: error.localizedDescription)
    }

    static func makeChainsSheet(_ networks: [BlockchainNetwork], onAcceptAction: @escaping (BlockchainNetwork) -> Void, onReject: @escaping () -> Void) -> UIAlertController {
        let vc: UIAlertController = UIAlertController(title: "WalletConnect", message: "wallet_connect_select_network".localized, preferredStyle: .actionSheet)

        for network in networks {
            let action = UIAlertAction(title: network.blockchain.displayName, style: .default, handler: { _ in onAcceptAction(network) })
            vc.addAction(action)
        }

        vc.addAction(UIAlertAction(title: "common_reject".localized, style: .cancel, handler: { _ in onReject() }))

        return vc
    }
}
