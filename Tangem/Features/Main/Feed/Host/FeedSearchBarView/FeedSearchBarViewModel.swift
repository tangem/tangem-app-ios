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

    var queryPublisher: AnyPublisher<String, Never> {
        $query.eraseToAnyPublisher()
    }

    var submitPublisher: AnyPublisher<Void, Never> {
        submitSubject.eraseToAnyPublisher()
    }

    private let submitSubject = PassthroughSubject<Void, Never>()

    func submit() {
        submitSubject.send()
    }
}
