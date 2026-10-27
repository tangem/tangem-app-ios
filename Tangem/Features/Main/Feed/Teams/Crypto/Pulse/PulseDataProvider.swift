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
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }

    func makeRowViewModel(for token: MarketsTokenModel, onTap: @escaping () -> Void) -> MarketTokenItemViewModel
    /// `isCategoryUserInitiated` is false when the view model dropped a category the tag does not support.
    func load(interval: PulseInterval, category: PulseCategory, tag: PulseTagSelection?, isCategoryUserInitiated: Bool)
    func loadMore()
    func setVisibleTokenIDs(_ ids: Set<String>)
    func suspendQuotes()
    func resumeQuotes()
}
