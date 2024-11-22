//
//  OnrampProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public class OnrampProvider {
    public let provider: ExpressProvider
    public let paymentMethod: OnrampPaymentMethod

    public private(set) var isBest: Bool = false

    private let manager: OnrampProviderManager

    init(
        provider: ExpressProvider,
        paymentMethod: OnrampPaymentMethod,
        manager: OnrampProviderManager
    ) {
        self.provider = provider
        self.paymentMethod = paymentMethod
        self.manager = manager
    }

    func update(isBest: Bool) {
        self.isBest = isBest
    }
}

// MARK: - OnrampProviderManagerProxy

extension OnrampProvider: OnrampProviderManager {
    public var state: OnrampProviderManagerState { manager.state }

    public var isSupported: Bool {
        state.isSupported
    }

    public var isLoading: Bool {
        switch state {
        case .loading: true
        case .idle, .loaded, .failed, .notSupported, .restriction: false
        }
    }

    public var canBeShow: Bool {
        switch state {
        case .restriction, .loaded: true
        case .idle, .loading, .failed, .notSupported: false
        }
    }

    public var canBeSelected: Bool {
        error == nil
    }

    public var isReadyToBuy: Bool {
        switch state {
        case .loaded: true
        case .idle, .loading, .failed, .notSupported, .restriction: false
        }
    }

    public var error: Error? {
        switch state {
        case .failed(let error): error
        case .restriction, .loaded, .idle, .loading, .notSupported: nil
        }
    }

    public func update(amount: Decimal?) async {
        await manager.update(amount: amount)
    }

    public func makeOnrampQuotesRequestItem() throws -> OnrampQuotesRequestItem {
        try manager.makeOnrampQuotesRequestItem()
    }
}

// MARK: - CustomStringConvertible

extension OnrampProvider: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: [
            "provider": provider.name,
            "paymentMethod": paymentMethod.name,
            "manager.state": manager.state,
        ])
    }
}
