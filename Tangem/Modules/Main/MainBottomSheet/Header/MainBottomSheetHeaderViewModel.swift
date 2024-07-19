//
//  MainBottomSheetHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainBottomSheetHeaderViewModel: ObservableObject {
    var enteredSearchTextPublisher: AnyPublisher<String, Never> {
        return $enteredSearchText.eraseToAnyPublisher()
    }

    @Published var enteredSearchText = ""
    @Published var inputShouldBecomeFocused = false

    func onBottomSheetAppear(isTapGesture: Bool) {
        if isTapGesture {
            inputShouldBecomeFocused = true
        }
    }

    func onBottomSheetDisappear() {
        // Needed to clear the token search field after the bottom sheet is collapsed
        enteredSearchText = ""
    }
}
