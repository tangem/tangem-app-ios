//
//  SearchInputSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
@testable import Tangem

final class SearchInputSpy {
    private(set) var events: [MarketsSearchHeaderViewModel.SearchInput] = []
    private var subscription: AnyCancellable?

    init(publisher: some Publisher<MarketsSearchHeaderViewModel.SearchInput, Never>) {
        subscription = publisher.sink { [weak self] in self?.events.append($0) }
    }
}
