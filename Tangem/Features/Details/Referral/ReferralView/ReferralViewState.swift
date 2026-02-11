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
        case plainUserTokensManager(UserTokensManager)
        case accounts(AccountModelsManager)
    }

    enum ViewState {
        case loading
        case loaded(LoadedState)
        case failed(reason: String)

        func updateAccountData(with newData: SelectedAccountViewData) -> Self {
            switch self {
            case .loading:
                return .loading

            case .loaded(let loadedState):
                return .loaded(loadedState.updateAccountData(with: newData))

            case .failed(let reason):
                return .failed(reason: reason)
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
                case .simple(let userTokensManager):
                    return .alreadyParticipant(.simple(userTokensManager))

                case .accounts:
                    return .alreadyParticipant(.accounts(newData))
                }

            case .readyToBecomeParticipant(let displayMode):
                switch displayMode {
                case .simple(let userTokensManager):
                    return .readyToBecomeParticipant(.simple(userTokensManager))

                case .accounts(let tokenItem, _):
                    return .readyToBecomeParticipant(.accounts(tokenItem, newData))
                }
            }
        }
    }

    enum AlreadyParticipantDisplayMode {
        case simple(UserTokensManager)
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
        case simple(UserTokensManager)
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
