//
//  TransactionRecord.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct TransactionRecord: Hashable {
    public let hash: String
    /// Index of an individual transaction within the parent transaction (if applicable).
    /// For example, a single EVM transaction may consist of multiple token transactions (with indices 0, 1, 2 and so on)
    public let index: Int
    public let source: SourceType
    public let destination: DestinationType
    public let fee: Fee
    public let status: TransactionStatus
    public let isOutgoing: Bool
    public let type: TransactionType
    public let date: Date?
    public let tokenTransfers: [TokenTransfer]
    public let isFromYieldContract: Bool
    /// For EVM only.
    public let nonce: Int?
    public var extraInfo: ExtraInfo? { _extraInfo?.wrapped }

    private let _extraInfo: AnyExtraInfo?

    public func hasDestination(address: String) -> Bool {
        switch destination {
        case .single(let destination):
            return destination.address.string.caseInsensitiveCompare(address) == .orderedSame
        case .multiple(let destinations):
            return destinations.contains { $0.address.string.caseInsensitiveCompare(address) == .orderedSame }
        }
    }

    public init(
        hash: String,
        index: Int,
        source: SourceType,
        destination: DestinationType,
        fee: Fee,
        status: TransactionStatus,
        isOutgoing: Bool,
        type: TransactionType,
        date: Date?,
        tokenTransfers: [TokenTransfer],
        isFromYieldContract: Bool = false,
        nonce: Int?,
        extraInfo: ExtraInfoType? = nil
    ) {
        self.index = index
        self.hash = hash
        self.source = source
        self.destination = destination
        self.fee = fee
        self.status = status
        self.isOutgoing = isOutgoing
        self.type = type
        self.date = date
        self.tokenTransfers = tokenTransfers
        self.isFromYieldContract = isFromYieldContract
        self.nonce = nonce
        _extraInfo = extraInfo.map(AnyExtraInfo.init)
    }
}

// MARK: - ID

public extension TransactionRecord {
    /// Lightweight, stable identity of a record — `hash` + `index`.
    struct ID: Hashable {
        public let hash: String
        public let index: Int

        public init(hash: String, index: Int) {
            self.hash = hash
            self.index = index
        }
    }

    var id: ID {
        ID(hash: hash, index: index)
    }
}

// MARK: - TransactionType

public extension TransactionRecord {
    enum TransactionType: Hashable {
        case transfer
        /// Contains contract method id (like `0x357a150b`).
        case contractMethodIdentifier(id: String)
        /// Contains human-readable contract method name (like `swap`).
        case contractMethodName(name: String?)
        case staking(type: StakingTransactionType, target: String?)

        public enum StakingTransactionType {
            case stake
            case unstake
            case vote
            case withdraw
            case claimRewards
            case restake
        }
    }
}

extension TransactionRecord.TransactionType {
    static var unknownOperation: Self { .contractMethodName(name: nil) }
}

// MARK: - TransactionStatus

public extension TransactionRecord {
    enum TransactionStatus: Hashable {
        case unconfirmed
        case failed
        case confirmed
        case undefined
    }
}

// MARK: - Source

public extension TransactionRecord {
    enum SourceType: Hashable {
        case single(Source)
        case multiple([Source])

        public var sources: [Source] {
            switch self {
            case .single(let source): [source]
            case .multiple(let sources): sources
            }
        }

        static func from(_ sources: [Source]) -> Self {
            if let source = sources.singleElement {
                return .single(source)
            }
            return .multiple(sources)
        }
    }

    struct Source: Hashable {
        public let address: String
        public let amount: Decimal

        public init(address: String, amount: Decimal) {
            self.address = address
            self.amount = amount
        }
    }
}

// MARK: - Destination

public extension TransactionRecord {
    enum DestinationType: Hashable {
        case single(Destination)
        case multiple([Destination])

        public var destinations: [Destination] {
            switch self {
            case .single(let destination): [destination]
            case .multiple(let destinations): destinations
            }
        }

        static func from(_ destinations: [Destination]) -> Self {
            if let destination = destinations.singleElement {
                return .single(destination)
            }
            return .multiple(destinations)
        }
    }

    struct Destination: Hashable {
        public let address: Address
        public let amount: Decimal

        public init(address: TransactionRecord.Destination.Address, amount: Decimal) {
            self.address = address
            self.amount = amount
        }

        public enum Address: Hashable {
            case user(String)
            /// Contact address for token-supported blockchains
            case contract(String)

            public var string: String {
                switch self {
                case .user(let address):
                    return address
                case .contract(let address):
                    return address
                }
            }
        }
    }
}

// MARK: - TokenTransfer

public extension TransactionRecord {
    struct TokenTransfer: Hashable {
        public let source: String
        public let destination: String
        public let amount: Decimal
        public let name: String?
        public let symbol: String?
        public let decimals: Int?
        public let contract: String?
    }
}

// MARK: - ExtraInfo

public extension TransactionRecord {
    typealias ExtraInfoType = any Hashable & ExtraInfo

    /// A marker-only protocol used for passing various opaque data between `BSDK` <-> `Express` <-> `App` domains.
    @_marker
    protocol ExtraInfo {}
}

// MARK: - Interoperability for `ExtraInfo` (private implementation)

private extension TransactionRecord {
    /// A type-erasing box around an `ExtraInfo` value. It's needed for three reasons:
    /// - Marker-only protocols can't inherit from other protocols, so `protocol ExtraInfo: Hashable {}` isn't allowed.
    /// - Existential types can't conform to protocols, so writing `let extraInfo: (any ExtraInfo & Hashable)?`
    ///   on `TransactionRecord` prevent compiler from synthesizing `Equatable` and `Hashable` conformances.
    /// - Generics don't fit either: they'd require fixing the concrete type at compile time, which requires specifying
    ///   a concrete type for optional extra info values instead of just `nil` for an absent value.
    struct AnyExtraInfo {
        let wrapped: ExtraInfoType
    }
}

extension TransactionRecord.AnyExtraInfo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrapped.isEqual(to: rhs.wrapped)
    }
}

extension TransactionRecord.AnyExtraInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        wrapped.hash(into: &hasher)
    }
}

private extension TransactionRecord.ExtraInfo where Self: Equatable {
    func isEqual(to other: TransactionRecord.ExtraInfo) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        return self == other
    }
}
