//
//  FeedSearchBarViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class FeedSearchBarViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var isFocused = false

    var queryPublisher: AnyPublisher<String, Never> {
        $query.eraseToAnyPublisher()
    }

    func endEditing() {
        guard isFocused else {
            return
        }

        isFocused = false
    }
}
