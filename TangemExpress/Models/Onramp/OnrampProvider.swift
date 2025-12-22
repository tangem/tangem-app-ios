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

    public private(set) var processingTimeType: ProcessingTimeType?
    public private(set) var globalAttractiveType: AttractiveType?

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

    func update(globalAttractiveType: AttractiveType?) {
        self.globalAttractiveType = globalAttractiveType
    }

    func update(processingTimeType: ProcessingTimeType?) {
        self.processingTimeType = processingTimeType
    }
}

// MARK: - AttractiveType

public extension OnrampProvider {
    enum ProcessingTimeType: Hashable, CustomStringConvertible {
        case fastest

        public var description: String {
            switch self {
            case .fastest: "Fastest"
            }
        }
    }

    enum AttractiveType: Hashable, CustomStringConvertible {
        case best
        case great(percent: Decimal?)
        case loss(percent: Decimal)

        public var isGreat: Bool {
            switch self {
            case .great: true
            case .best, .loss: false
            }
        }

        public var description: String {
            switch self {
            case .best: "Best"
            case .great(let percent): "Great \(String(describing: percent))"
            case .loss(let percent): "Loss \(percent)"
            }
        }
    }
}

// MARK: - Hashable

extension OnrampProvider: Hashable {
    public static func == (lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(provider)
        hasher.combine(paymentMethod)
        hasher.combine(state)
        hasher.combine(processingTimeType)
        hasher.combine(globalAttractiveType)
    }
}

// MARK: - Comparable

extension OnrampProvider: Comparable {
    public static func < (lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
        switch (lhs.state, rhs.state) {
        // 1) Same amount and processing time: lower priority value first
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)) where lhsQuote.expectedAmount == rhsQuote.expectedAmount && lhs.paymentMethod.type.processingTime == rhs.paymentMethod.type.processingTime:
            return lhs.paymentMethod.type.priority < rhs.paymentMethod.type.priority

        // 2) Same amount, different processing time: shorter first
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)) where lhsQuote.expectedAmount == rhsQuote.expectedAmount:
            return lhs.paymentMethod.type.processingTime < rhs.paymentMethod.type.processingTime

        // 3) Different expected amounts: higher first
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)):
            return lhsQuote.expectedAmount > rhsQuote.expectedAmount

        // 4) Loaded is always before non-loaded
        case (.loaded, _):
            return true

        // 5) Restrictions: place after loaded/non-restricted states
        case (.restriction(let lhsRestriction), .restriction(let rhsRestriction)):
            let lhsDiff = (lhs.amount ?? 0) - lhsRestriction.amount
            let rhsDiff = (rhs.amount ?? 0) - rhsRestriction.amount
            return abs(lhsDiff) < abs(rhsDiff)

        // For other states (idle, loading, failed, notSupported), keep deterministic but after loaded
        default:
            return false
        }
    }
}

// MARK: - OnrampProviderManagerProxy

extension OnrampProvider: OnrampProviderManager {
    public var state: OnrampProviderManagerState { manager.state }
    public var amount: Decimal? { manager.amount }

    public var isSupported: Bool {
        state.isSupported
    }

    /// Can be used for showing user
    public var isShowable: Bool {
        switch state {
        case .idle, .restriction, .loaded: true
        case .notSupported(.paymentMethod(let methods)) where !methods.isEmpty: true
        case .loading, .failed, .notSupported: false
        }
    }

    /// Can be used as `_selectedProvider`
    public var isSelectable: Bool {
        switch state {
        case .idle, .loading, .restriction, .loaded, .failed: true
        case .notSupported: false
        }
    }

    /// Successfully loaded or loaded with a limit error
    public var isLoaded: Bool {
        switch state {
        case .restriction, .loaded: true
        case .idle, .loading, .failed, .notSupported: false
        }
    }

    public var isSuccessfullyLoaded: Bool {
        switch state {
        case .loaded: true
        case .idle, .loading, .failed, .notSupported, .restriction: false
        }
    }

    public var quote: OnrampQuote? {
        switch state {
        case .loaded(let quote): quote
        case .restriction, .failed, .idle, .loading, .notSupported: nil
        }
    }

    public var error: Error? {
        switch state {
        case .failed(let error): error
        case .restriction, .loaded, .idle, .loading, .notSupported: nil
        }
    }

    public func update(supportedMethods: [OnrampPaymentMethod]) {
        manager.update(supportedMethods: supportedMethods)
    }

    public func update(amount: OnrampUpdatingAmount) async {
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
            "processingTimeType": processingTimeType as Any,
            "globalAttractiveType": globalAttractiveType as Any,
        ])
    }
}
