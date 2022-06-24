//
//  ChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import MessagingSDK
import SupportSDK
import SwiftUI

struct SupportChatView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        do {
            return try buildUI()
        } catch {
            return UIViewController(nibName: nil, bundle: nil)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }

    func buildUI() throws -> UIViewController {
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = "Tangem"
        let supportEngine = try SupportEngine.engine()
        return try Messaging.instance.buildUI(engines: [supportEngine],
                                              configs: [messagingConfiguration])
    }
}
