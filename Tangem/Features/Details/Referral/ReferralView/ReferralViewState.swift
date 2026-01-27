//
//  ReferralViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import TangemUI

extension ReferralViewModel {
    enum WorkMode {
        case plainUserTokensManager(any UserTokensManager)
        case accounts(AccountModelsManager)
    }

    enum ViewState {
        case loading
        case loaded(LoadedState)

        func updateAccountData(with newData: SelectedAccountViewData) -> Self {
            switch self {
            case .loading:
                return .loading

            case .loaded(let loadedState):
                return .loaded(loadedState.updateAccountData(with: newData))
            }
        }
    }

    enum LoadedState {
        case alreadyParticipant(AlreadyParticipantDisplayMode)
        case readyToBecomeParticipant(ReadyToBecomeParticipantDisplayMode)

        var accountData: SelectedAccountViewData? {
            switch self {
            case .alreadyParticipant(let displayMode):
                return displayMode.accountData

            case .readyToBecomeParticipant(let displayMode):
                return displayMode.accountData
            }
        }

        func updateAccountData(with newData: SelectedAccountViewData) -> Self {
            switch self {
            case .alreadyParticipant(let displayMode):
                switch displayMode {
                case .simple:
                    return .alreadyParticipant(.simple)

                case .accounts:
                    return .alreadyParticipant(.accounts(newData))
                }

            case .readyToBecomeParticipant(let displayMode):
                switch displayMode {
                case .simple:
                    return .readyToBecomeParticipant(.simple)

                case .accounts(let tokenItem, _):
                    return .readyToBecomeParticipant(.accounts(tokenItem, newData))
                }
            }
        }
    }

    enum AlreadyParticipantDisplayMode {
        case simple
        case accounts(SelectedAccountViewData)

        var accountData: SelectedAccountViewData? {
            switch self {
            case .simple:
                return nil
            case .accounts(let data):
                return data
            }
        }
    }

    enum ReadyToBecomeParticipantDisplayMode {
        case simple
        case accounts(TokenType, SelectedAccountViewData)

        enum TokenType {
            case token(TokenIconInfo, String, String)
            case tokenItem(ExpressTokenItemViewModel)
        }

        var accountData: SelectedAccountViewData? {
            switch self {
            case .simple:
                return nil
            case .accounts(_, let data):
                return data
            }
        }
    }

    struct SelectedAccountViewData {
        let id: AnyHashable
        let iconViewData: AccountIconView.ViewData
        let name: String
    }
}
