//
//  ForYouSelectedAccountsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class ForYouSelectedAccountsProvider {
    private let selectionSubject: CurrentValueSubject<ForYouAccountSelection, Never>

    var selection: ForYouAccountSelection {
        selectionSubject.value
    }

    var selectionPublisher: AnyPublisher<ForYouAccountSelection, Never> {
        selectionSubject.eraseToAnyPublisher()
    }

    init(selection: ForYouAccountSelection = .all) {
        selectionSubject = .init(selection)
    }

    func select(_ selection: ForYouAccountSelection) {
        selectionSubject.send(selection)
    }
}
