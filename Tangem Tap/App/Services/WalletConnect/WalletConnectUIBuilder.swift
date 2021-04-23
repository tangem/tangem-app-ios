//
//  WalletConnectUIBuilder.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WalletConnectEvent {
    case establishSession, sign, sendTx
}

enum WalletConnectUIBuilder {
    static func makeUI(for event: WalletConnectEvent) -> UIViewController {
        let vc: UIViewController = UIHostingController(rootView: Text("Establish session"))
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
    
    static func makeAlert(for event: WalletConnectEvent, message: String, onAcceptAction: @escaping () -> Void, isAcceptEnabled: Bool, onReject: @escaping () -> Void) -> UIAlertController {
        let vc: UIAlertController = UIAlertController(title: "WalletConnect", message: message, preferredStyle: .alert)
        let buttonTitle: String
        switch event {
        case .establishSession:
            buttonTitle = "Start"
        case .sign:
            buttonTitle = "Sign"
        case .sendTx:
            buttonTitle = "Sign and Send"
        }
        vc.addAction(UIAlertAction(title: "Reject", style: .cancel, handler: { _ in onReject() }))
        let acceptButton = UIAlertAction(title: buttonTitle, style: .default, handler: { _ in onAcceptAction() })
        acceptButton.isEnabled = isAcceptEnabled
        vc.addAction(acceptButton)
        return vc
    }
}
