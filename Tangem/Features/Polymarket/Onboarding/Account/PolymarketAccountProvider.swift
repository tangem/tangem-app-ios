//
//  PolymarketAccountProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

struct PolymarketAccountProvider {
    private let accountModel: ThreadSafeLazy<any PolymarketAccountModel>

    @Injected(\.polymarketAvailabilityProvider) private var availabilityProvider: PolymarketAvailabilityProvider

    init(builder: PolymarketAccountBuilder) {
        accountModel = ThreadSafeLazy(builder.buildAccountModel)
    }
}

// MARK: - AccountModelsProvider protocol conformance

extension PolymarketAccountProvider: AccountModelsProvider {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        availabilityProvider
            .isAvailablePublisher
            .handleEvents(receiveOutput: { [accountModel] isAvailable in
                guard isAvailable else { return }

                loadStateIfNeeded(of: accountModel.value)
            })
            .map { [accountModel] isAvailable in
                isAvailable ? [.polymarket(accountModel.value)] : []
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension PolymarketAccountProvider {
    /// The screens ask for the state when they appear, and the account can arrive after that, once the
    /// experiment resolves. Without this read its state stays nil and the row never shows up.
    func loadStateIfNeeded(of accountModel: any PolymarketAccountModel) {
        guard accountModel.state == nil else { return }

        runTask { await accountModel.refreshState() }
    }
}
