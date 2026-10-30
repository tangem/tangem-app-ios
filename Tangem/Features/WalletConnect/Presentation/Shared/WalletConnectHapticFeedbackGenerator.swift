//
//  WalletConnectHapticFeedbackGenerator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectHapticFeedbackGenerator {
    func prepareNotificationFeedback()
    func successNotificationOccurred()
    func warningNotificationOccurred()
    func errorNotificationOccurred()
}
