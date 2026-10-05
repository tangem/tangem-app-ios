//
//  FeedbackGenerator.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

public enum FeedbackGenerator {
    public static func heavy() {
        heavyImpactGenerator.impactOccurred()
    }

    public static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    public static func selectionChanged() {
        lightImpactGenerator.impactOccurred()
    }

    public static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    public static func selection() {
        selectionGenerator.selectionChanged()
    }

    public static func soft() {
        softImpactGenerator.impactOccurred()
    }

    private static let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
}
