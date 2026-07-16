//
//  MainBottomSheetHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

final class MainBottomSheetHeaderViewModel: ObservableObject {
    var enteredSearchInputPublisher: AnyPublisher<SearchInput, Never> {
        searchInputSubject.eraseToAnyPublisher()
    }

    @Published var enteredSearchText = ""
    @Published var inputShouldBecomeFocused = false

    let searchPlaceholder = Localization.marketsSearchTitlePlaceholder

    private let searchInputSubject = CurrentValueSubject<SearchInput, Never>(.textInput(""))
    private var shouldSkipNextTextInput = false

    private var inputSubscription: AnyCancellable?

    weak var delegate: MainBottomSheetHeaderViewModelDelegate?

    init() {
        bind()
    }

    func onBottomSheetExpand(isTapGesture: Bool) {
        guard
            isTapGesture,
            // In the redesign the search field opens only on a tap when the sheet is already expanded,
            // so expanding the sheet itself must not focus the input.
            !FeatureProvider.isAvailable(.redesign),
            delegate?.isViewVisibleForHeaderViewModel(self) == true
        else {
            return
        }

        inputShouldBecomeFocused = true
    }

    func focusSearchBarAction() {
        inputShouldBecomeFocused = true
    }

    func clearSearchBarAction() {
        if enteredSearchText.isEmpty {
            return
        }

        searchInputSubject.send(.clearInput)
        shouldSkipNextTextInput = true
        enteredSearchText = ""
    }

    func cancelSearchBarAction() {
        searchInputSubject.send(.cancelInput)
        shouldSkipNextTextInput = true
        enteredSearchText = ""
        inputShouldBecomeFocused = false
    }

    func focusChangedAction(_ focused: Bool) {
        syncWithInput(focused: focused)
    }

    func lostInputFocus() {
        inputShouldBecomeFocused = false
    }

    private func bind() {
        inputSubscription = $enteredSearchText
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .filter { viewModel, input in
                if viewModel.shouldSkipNextTextInput {
                    viewModel.shouldSkipNextTextInput = false
                    return false
                }

                return true
            }
            .map { SearchInput.textInput($1) }
            .assign(to: \.value, on: searchInputSubject, ownership: .weak)
    }

    private func syncWithInput(focused: Bool) {
        if inputShouldBecomeFocused != focused {
            inputShouldBecomeFocused = focused
        }
    }
}

extension MainBottomSheetHeaderViewModel {
    enum SearchInput: Equatable {
        case textInput(String)
        case clearInput
        case cancelInput

        var textValue: String? {
            switch self {
            case .textInput(let textInput): return textInput
            case .clearInput: return nil
            case .cancelInput: return nil
            }
        }

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
