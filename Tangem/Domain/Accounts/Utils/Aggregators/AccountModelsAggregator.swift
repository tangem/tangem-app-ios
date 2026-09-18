//
//  AccountModelsAggregator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Kinds as unlike each other as a crypto account and a TangemPay one, asked for together and answering with what they
/// have in common: `BaseAccountModelsAggregator(.crypto, .tangemPay)`.
typealias BaseAccountModelsAggregator = AccountModelsAggregator<[any BaseAccountModel], [BaseAccountModelsSelector]>

/**
 Takes accounts of one or more kinds out of a wallet's account list.

 What is taken is decided by the selectors alone, so a call site names the kinds it wants and is given nothing else.
 What may be asked follows from those same selectors and from the shape of their answer, which keeps a question that
 makes no sense out of the code instead of answering it with an empty list.

 A kind a wallet may hold several of answers with a list:

 ```swift
 let accounts = AccountModelsAggregator(.crypto).models(from: userWalletModel.accountModelsManager)
 let accountsPublisher = AccountModelsAggregator(.crypto).modelsPublisher(from: accountModelsManager)
 let acrossWallets = AccountModelsAggregator(.crypto).models(from: userWalletRepository.models)
 ```

 Several kinds are asked for together — here the wallet's own crypto accounts and the joint ones it takes part in:

 ```swift
 let accounts = AccountModelsAggregator(.crypto, .joint).models(from: accountModelsManager)
 ```

 A kind a wallet holds at most one of answers with the account itself:

 ```swift
 let tangemPay = AccountModelsAggregator(.tangemPay).model(from: accountModelsManager)
 let polymarket = AccountModelsAggregator(.polymarket).modelPublisher(from: accountModelsManager)
 ```

 The two never cross over: `model(from:)` is gone as soon as several kinds are asked for, and a kind a wallet holds at
 most one of has no `models(from:)` to give.

 - Note: An answer of several kinds comes kind by kind, in the order the kinds were asked for. The account list is
 built kind by kind as well, so the two orders coincide for as long as it is.
 - Note: A kind is added by writing an `AccountModelsSelector`, not by touching this type.
 */
struct AccountModelsAggregator<Models, Selectors> {
    private let selectors: Selectors

    init(_ selector: any AccountModelsSelector<Models>) where Selectors == any AccountModelsSelector<Models> {
        selectors = selector
    }

    init(_ selectors: any AccountModelsSelector<Models>...) where Selectors == [any AccountModelsSelector<Models>] {
        self.selectors = selectors
    }
}

// MARK: - One kind a wallet may hold several of

extension AccountModelsAggregator where Selectors == any AccountModelsSelector<Models>, Models: RangeReplaceableCollection {
    func models(from accountModels: [AccountModel]) -> Models {
        selectors.select(from: accountModels)
    }

    func models(from accountModelsManager: AccountModelsManager) -> Models {
        models(from: accountModelsManager.accountModels)
    }

    func models(from userWalletModels: [any UserWalletModel]) -> Models {
        userWalletModels.reduce(into: Models()) { $0.append(contentsOf: models(from: $1.accountModelsManager)) }
    }

    func modelsPublisher(from accountModelsManager: AccountModelsManager) -> AnyPublisher<Models, Never> {
        selectors.selectedPublisher(from: accountModelsManager.accountModelsPublisher)
    }
}

// MARK: - Several kinds at once

extension AccountModelsAggregator where Selectors == [any AccountModelsSelector<Models>], Models: RangeReplaceableCollection {
    func models(from accountModelsManager: AccountModelsManager) -> Models {
        models(from: accountModelsManager.accountModels)
    }

    func models(from userWalletModels: [any UserWalletModel]) -> Models {
        userWalletModels.reduce(into: Models()) { $0.append(contentsOf: models(from: $1.accountModelsManager)) }
    }

    func modelsPublisher(from accountModelsManager: AccountModelsManager) -> AnyPublisher<Models, Never> {
        // One pass over one answer rather than a branch per kind: branches of the same source come round one at a
        // time, and until they all had, the answer would carry one kind's new accounts beside another's old ones
        accountModelsManager
            .accountModelsPublisher
            .map { models(from: $0) }
            .eraseToAnyPublisher()
    }

    func models(from accountModels: [AccountModel]) -> Models {
        // Each kind is asked about the whole list at once, so that one a wallet holds at most one of can still tell
        // that it has been handed two
        selectors.reduce(into: Models()) { $0.append(contentsOf: $1.select(from: accountModels)) }
    }
}

// MARK: - A kind a wallet holds at most one of

extension AccountModelsAggregator where Selectors == any AccountModelsSelector<Models> {
    func model<Wrapped>(from accountModels: [AccountModel]) -> Wrapped? where Models == Wrapped? {
        selectors.select(from: accountModels)
    }

    func model<Wrapped>(from accountModelsManager: AccountModelsManager) -> Wrapped? where Models == Wrapped? {
        model(from: accountModelsManager.accountModels)
    }

    func modelPublisher<Wrapped>(
        from accountModelsManager: AccountModelsManager
    ) -> AnyPublisher<Wrapped?, Never> where Models == Wrapped? {
        selectors.selectedPublisher(from: accountModelsManager.accountModelsPublisher)
    }
}
