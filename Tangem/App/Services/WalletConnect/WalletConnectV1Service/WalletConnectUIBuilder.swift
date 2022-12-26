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

struct WalletConnectUIRequest {
    let event: WalletConnectEvent
    let message: String
    var positiveReactionAction: (() -> Void)?
    var negativeReactionAction: (() -> Void)?
}

protocol WalletConnectUIDelegate {
    func showScreen(with request: WalletConnectUIRequest)
}

struct WalletConnectAlertUIDelegate {
    private let appPresenter: AppPresenter = .shared
}

extension WalletConnectAlertUIDelegate: WalletConnectUIDelegate {
    func showScreen(with request: WalletConnectUIRequest) {

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
            buttonTitle = Localization.commonStart
        case .sign:
            buttonTitle = Localization.commonSign
        case .sendTx:
            buttonTitle = Localization.commonSignAndSend
        case .error, .success:
            buttonTitle = Localization.commonOk
        }

        if event.withCancelButton {
            vc.addAction(UIAlertAction(title: Localization.commonReject, style: .cancel, handler: { _ in onReject() }))
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
        let vc: UIAlertController = UIAlertController(title: "WalletConnect", message: Localization.walletConnectSelectNetwork, preferredStyle: .actionSheet)

        for network in networks {
            let action = UIAlertAction(title: network.blockchain.displayName, style: .default, handler: { _ in onAcceptAction(network) })
            vc.addAction(action)
        }

        vc.addAction(UIAlertAction(title: Localization.commonReject, style: .cancel, handler: { _ in onReject() }))

        return vc
    }
}
