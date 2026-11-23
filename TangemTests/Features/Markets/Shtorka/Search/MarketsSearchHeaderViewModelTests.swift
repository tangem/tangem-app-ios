//
//  MarketsSearchHeaderViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Markets search header input events")
struct MarketsSearchHeaderViewModelTests {
    @Test("Clearing after the field already emptied the text still emits the clear event")
    func clearAfterFieldEmptiedText() {
        let (sut, recorder) = makeSUT()

        sut.enteredSearchText = "btc"
        sut.enteredSearchText = ""
        sut.clearSearchBarAction()

        #expect(recorder.events == [.textInput(""), .textInput("btc"), .textInput(""), .clearInput])
    }

    @Test("Cancelling emits the cancel event and drops the focus")
    func cancelDropsFocus() {
        let (sut, recorder) = makeSUT()

        sut.inputShouldBecomeFocused = true
        sut.enteredSearchText = "btc"
        sut.enteredSearchText = ""
        sut.cancelSearchBarAction()

        #expect(recorder.events == [.textInput(""), .textInput("btc"), .textInput(""), .cancelInput])
        #expect(sut.inputShouldBecomeFocused == false)
    }

    @Test("The first keystroke after clear or cancel is not swallowed", arguments: [SearchAction.clear, .cancel])
    func firstKeystrokeAfterResetIsKept(action: SearchAction) {
        let (sut, recorder) = makeSUT()

        sut.enteredSearchText = "btc"
        sut.enteredSearchText = ""
        action.perform(on: sut)
        sut.enteredSearchText = "e"

        #expect(recorder.events.last == .textInput("e"))
    }
}

// MARK: - Helpers

extension MarketsSearchHeaderViewModelTests {
    enum SearchAction: CaseIterable, CustomTestStringConvertible {
        case clear
        case cancel

        var testDescription: String {
            switch self {
            case .clear: "clear"
            case .cancel: "cancel"
            }
        }

        func perform(on sut: MarketsSearchHeaderViewModel) {
            switch self {
            case .clear: sut.clearSearchBarAction()
            case .cancel: sut.cancelSearchBarAction()
            }
        }
    }
}

private extension MarketsSearchHeaderViewModelTests {
    func makeSUT() -> (MarketsSearchHeaderViewModel, SearchInputSpy) {
        let sut = MarketsSearchHeaderViewModel()
        let spy = SearchInputSpy(publisher: sut.enteredSearchInputPublisher)
        return (sut, spy)
    }
}
