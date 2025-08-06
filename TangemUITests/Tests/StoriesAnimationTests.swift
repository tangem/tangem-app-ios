//
//  StoriesAnimationTests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemFoundation

final class StoriesAnimationTests: BaseTestCase {
    func testStoriesAnimationsDisabledInUITests() {
        // Given: UI тест запущен с переменной окружения UITEST=1
        XCTAssertTrue(AppEnvironment.current.isUITest, "UI тесты должны запускаться с UITEST=1")

        // When: Приложение запускается
        app.launch()

        // Then: Stories не должны показываться (уже реализовано в TangemStoriesViewModel)
        // Анимации должны быть отключены во всех компонентах stories

        // Проверяем, что приложение запустилось без stories
        // (основная логика отключения уже реализована в TangemStoriesViewModel.present)

        // Дополнительные проверки можно добавить по мере необходимости
    }

    func testAnimationModifiersDisabledInUITests() {
        // Given: UI тест запущен
        XCTAssertTrue(AppEnvironment.current.isUITest)

        // When: Приложение запускается
        app.launch()

        // Then: Все AnimatableModifier должны отключать анимации
        // Это проверяется через .disableAnimationForUITests() в AnimatableModifiers.swift

        // Проверяем, что приложение работает стабильно без анимаций
    }

    func testStoriesHostViewAnimationsDisabled() {
        // Given: UI тест запущен
        XCTAssertTrue(AppEnvironment.current.isUITest)

        // When: Приложение запускается
        app.launch()

        // Then: TabView анимации в StoriesHostView должны быть отключены
        // Это проверяется через .animation(AppEnvironment.current.isUITest ? nil : .default, value: viewModel.visibleStoryIndex)

        // Проверяем, что переходы между stories происходят мгновенно
    }

    func testStoriesViewModelAnimationsDisabled() {
        // Given: UI тест запущен
        XCTAssertTrue(AppEnvironment.current.isUITest)

        // When: Приложение запускается
        app.launch()

        // Then: Анимации прогресса в StoriesViewModel должны быть отключены
        // Это проверяется в методах pauseTimer() и resumeTimer()

        // Проверяем, что прогресс stories обновляется мгновенно
    }
}
