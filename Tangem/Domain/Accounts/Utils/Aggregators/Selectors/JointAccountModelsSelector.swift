//
//  JointAccountModelsSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The joint accounts a wallet takes part in — it may take part in several — that are in the state being asked about.
/// An account still being put together holds no tokens and is shown by a plate of its own, so `.pending` and `.active`
/// are rarely wanted together; a call site that treats a joint account as an account whatever has become of it asks
/// for `.all`.
/// - Warning: A status this version doesn't know answers to neither `.pending` nor `.active`, so naming one of them
/// leaves such an account out of the answer altogether. Only `.all` keeps it.
struct JointAccountModelsSelector: AccountModelsSelector {
    let state: JointAccountState

    func select(from accountModels: [AccountModel]) -> [any JointAccountModel] {
        let jointAccountModels = accountModels.flatMap { accountModel -> [any JointAccountModel] in
            switch accountModel {
            case .standard: []
            case .joint(let jointAccountModels): jointAccountModels
            case .tangemPay, .polymarket, .collectibles: []
            }
        }

        return jointAccountModels.filter { state.isMatching(status: $0.status) }
    }

    func selectedPublisher(
        from accountModelsPublisher: AnyPublisher<[AccountModel], Never>
    ) -> AnyPublisher<[any JointAccountModel], Never> {
        accountModelsPublisher
            .map(select(from:))
            .eraseToAnyPublisher()
    }
}

extension JointAccountModelsSelector {
    enum JointAccountState {
        /// Whatever state it is in, a status this version has never heard of included.
        case all
        /// Still being put together: slots left to take, or the address announced and the creator yet to activate it.
        case pending
        case active

        func isMatching(status: JointAccountStatus) -> Bool {
            switch self {
            case .all: true
            case .pending: status.isPending || status.isConfirming
            case .active: status.isActive
            }
        }
    }
}

extension AccountModelsSelector where Self == JointAccountModelsSelector {
    static var joint: Self {
        joint(.all)
    }

    static func joint(_ state: JointAccountModelsSelector.JointAccountState) -> Self {
        JointAccountModelsSelector(state: state)
    }
}
