//
//  View+UITestAnimations.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Отключает анимации для UI тестов
    /// Используется для повышения скорости и стабильности UI тестов
    func disableAnimationForUITests() -> some View {
        transaction { transaction in
            if AppEnvironment.current.isUITest {
                transaction.animation = nil
            }
        }
    }

    /// Применяет анимацию только если не запущены UI тесты
    /// - Parameter animation: Анимация для применения
    /// - Returns: View с условной анимацией
    func conditionalAnimation(_ animation: Animation?) -> some View {
        self.animation(AppEnvironment.current.isUITest ? nil : animation)
    }

    /// Применяет анимацию с значением только если не запущены UI тесты
    /// - Parameters:
    ///   - animation: Анимация для применения
    ///   - value: Значение для отслеживания изменений
    /// - Returns: View с условной анимацией
    func conditionalAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.animation(AppEnvironment.current.isUITest ? nil : animation, value: value)
    }
}
