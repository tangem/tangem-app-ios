//
//  MultiWalletMainContentViewSectionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MultiWalletMainContentViewSectionsProvider {
    associatedtype PlainSectionsPublisher: Publisher<[MultiWalletMainContentPlainSection], Never>
    associatedtype AccountsSectionsPublisher: Publisher<[MultiWalletMainContentAccountSection], Never>

    /// - Note: Always returns shared publisher.
    func makePlainSectionsPublisher() -> PlainSectionsPublisher

    /// - Note: Always returns shared publisher.
    func makeAccountSectionsPublisher() -> AccountsSectionsPublisher

    func configure(with itemViewModelFactory: MultiWalletMainContentItemViewModelFactory)
}
