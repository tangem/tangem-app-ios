//
//  FeedbackGenerator.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

public enum FeedbackGenerator {
    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    public static func selectionChanged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
