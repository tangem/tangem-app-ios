//
//  MarketsSearchHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

final class MarketsSearchHeaderViewModel: ObservableObject {
    var enteredSearchInputPublisher: AnyPublisher<SearchInput, Never> {
        searchInputSubject.eraseToAnyPublisher()
    }

    @Published var enteredSearchText = ""
    @Published var inputShouldBecomeFocused = false

    let searchPlaceholder = Localization.marketsSearchTitlePlaceholder

    private let searchInputSubject = CurrentValueSubject<SearchInput, Never>(.textInput(""))

    private var inputSubscription: AnyCancellable?

    init() {
        bind()
    }

    func clearSearchBarAction() {
        searchInputSubject.send(.clearInput)
    }

    func cancelSearchBarAction() {
        searchInputSubject.send(.cancelInput)
        inputShouldBecomeFocused = false
    }

    private func bind() {
        inputSubscription = $enteredSearchText
            .removeDuplicates()
            .map { SearchInput.textInput($0) }
            .assign(to: \.value, on: searchInputSubject, ownership: .weak)
    }
}

extension MarketsSearchHeaderViewModel {
    enum SearchInput: Equatable {
        case textInput(String)
        case clearInput
        case cancelInput

        static func == (lhs: SearchInput, rhs: SearchInput) -> Bool {
            switch (lhs, rhs) {
            case (.textInput(let lhsText), .textInput(let rhsText)):
                return lhsText.compare(rhsText) == .orderedSame
            case (.clearInput, .clearInput):
                return true
            case (.cancelInput, .cancelInput):
                return true
            default:
                return false
            }
        }
    }
}
