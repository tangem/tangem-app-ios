//
//  ErasedAccountModelsSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Another selector's answer taken as a kind of account model further up the hierarchy, which is what lets kinds that
/// answer differently be asked for side by side. Built through `erased(as:)`.
///
/// Both of the selector's answers are carried over, the one it gives a publisher included, so that what it does there
/// — weeding out a repeated answer, say — is not quietly dropped on the way up.
struct ErasedAccountModelsSelector<Model>: AccountModelsSelector {
    private let erasedSelect: ([AccountModel]) -> [Model]
    private let erasedSelectedPublisher: (AnyPublisher<[AccountModel], Never>) -> AnyPublisher<[Model], Never>

    fileprivate init(
        select: @escaping ([AccountModel]) -> [Model],
        selectedPublisher: @escaping (AnyPublisher<[AccountModel], Never>) -> AnyPublisher<[Model], Never>
    ) {
        erasedSelect = select
        erasedSelectedPublisher = selectedPublisher
    }

    func select(from accountModels: [AccountModel]) -> [Model] {
        erasedSelect(accountModels)
    }

    func selectedPublisher(from accountModelsPublisher: AnyPublisher<[AccountModel], Never>) -> AnyPublisher<[Model], Never> {
        erasedSelectedPublisher(accountModelsPublisher)
    }
}

// MARK: - Taking an answer as a kind further up the hierarchy

extension AccountModelsSelector where Models: Sequence {
    /// The kind to take the answer as is the one `transform` returns, so the compiler is the one to say whether the
    /// answer is a kind of it at all.
    func erased<Model>(as transform: @escaping (Models.Element) -> Model) -> ErasedAccountModelsSelector<Model> {
        ErasedAccountModelsSelector(
            select: { [self] accountModels in
                select(from: accountModels).map(transform)
            },
            selectedPublisher: { [self] accountModelsPublisher in
                selectedPublisher(from: accountModelsPublisher)
                    .map { $0.map(transform) }
                    .eraseToAnyPublisher()
            }
        )
    }
}

extension AccountModelsSelector {
    func erased<Wrapped, Model>(
        as transform: @escaping (Wrapped) -> Model
    ) -> ErasedAccountModelsSelector<Model> where Models == Wrapped? {
        ErasedAccountModelsSelector(
            select: { [self] accountModels in
                select(from: accountModels).map { [transform($0)] } ?? []
            },
            selectedPublisher: { [self] accountModelsPublisher in
                selectedPublisher(from: accountModelsPublisher)
                    .map { $0.map { [transform($0)] } ?? [] }
                    .eraseToAnyPublisher()
            }
        )
    }
}

// MARK: - As crypto accounts

extension AccountModelsSelector where Self == ErasedAccountModelsSelector<any CryptoAccountModel> {
    /// The joint accounts a wallet takes part in, reported as the crypto accounts they also are, so that a call site
    /// can ask for them alongside the wallet's own ones. Whatever state they are in — a call site that cares names it
    /// with `joint(_:)`.
    /// - Warning: A joint account is operated by its members together, so anything that goes on to sign for what it
    /// finds here has to tell the two kinds apart itself.
    static var joint: Self {
        joint(.all)
    }

    static func joint(_ state: JointAccountModelsSelector.JointAccountState) -> Self {
        JointAccountModelsSelector(state: state).erased { $0 }
    }
}

// MARK: - As plain account models

extension AccountModelsSelector where Self == ErasedAccountModelsSelector<any BaseAccountModel> {
    static var crypto: Self {
        CryptoAccountModelsSelector().erased { $0 }
    }

    static var joint: Self {
        joint(.all)
    }

    static func joint(_ state: JointAccountModelsSelector.JointAccountState) -> Self {
        JointAccountModelsSelector(state: state).erased { $0 }
    }

    static var tangemPay: Self {
        TangemPayAccountModelSelector().erased { $0 }
    }
}
