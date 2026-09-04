//
//  PulseDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol PulseDataProvider {
    var tokensPublisher: AnyPublisher<[MarketsTokenModel], Never> { get }
    var failedPublisher: AnyPublisher<Bool, Never> { get }
    var canLoadMore: Bool { get }

    func makeRowViewModel(for token: MarketsTokenModel, onTap: @escaping () -> Void) -> MarketTokenItemViewModel
    func load(interval: PulseInterval, category: PulseCategory)
    func loadMore()
    func setVisibleTokenIDs(_ ids: Set<String>)
    func suspendQuotes()
    func resumeQuotes()
}
