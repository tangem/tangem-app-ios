//
//  WalletConnectUIFeedbackGenerator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

final class WalletConnectUIFeedbackGenerator: WalletConnectHapticFeedbackGenerator {
    private let selectionFeedbackGenerator: UISelectionFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator

    init() {
        selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()
    }

    func prepareNotificationFeedback() {
        notificationGenerator.prepare()
    }

    func successNotificationOccurred() {
        notificationGenerator.notificationOccurred(.success)
    }

    func warningNotificationOccurred() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func errorNotificationOccurred() {
        notificationGenerator.notificationOccurred(.error)
    }
}
