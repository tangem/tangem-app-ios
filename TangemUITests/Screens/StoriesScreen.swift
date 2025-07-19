//
//  StoriesScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StoriesScreen: ScreenBase<StoriesScreenElement> {
    private lazy var scanButton = button(.scanButton)

    @discardableResult
    func scanMockWallet(name: CardMockAccessibilityIdentifiers) -> MainScreen {
        XCTContext.runActivity(named: "Scan Mock Wallet: \(name)") { _ in
            scanButton.waitAndTap(timeout: .longUIUpdate)

            // Дополнительное ожидание появления mock wallet buttons
            let walletButton = app.buttons[name.rawValue]

            // Увеличиваем timeout для CI и добавляем дополнительную диагностику
            guard walletButton.waitForExistence(timeout: .criticalUIOperation) else {
                // Диагностическая информация при неудаче
                let availableButtons = app.buttons.allElementsBoundByIndex.map { $0.identifier }
                XCTFail("Mock wallet button '\(name.rawValue)' not found. Available buttons: \(availableButtons)")
                return MainScreen(app)
            }

            // Дополнительная проверка видимости и доступности
            guard walletButton.isHittable else {
                XCTFail("Mock wallet button '\(name.rawValue)' exists but not hittable")
                return MainScreen(app)
            }

            walletButton.waitAndTap(timeout: .criticalUIOperation, waitForHittable: true)

            return MainScreen(app)
        }
    }
}

enum StoriesScreenElement: String, UIElement {
    case scanButton

    var accessibilityIdentifier: String {
        switch self {
        case .scanButton:
            StoriesAccessibilityIdentifiers.scanButton
        }
    }
}
