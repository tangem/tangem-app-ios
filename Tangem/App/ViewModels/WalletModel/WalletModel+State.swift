//
//  WalletModel+State.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension WalletModel {
    enum State: Hashable, CustomStringConvertible {
        case created
        case loaded(Decimal)
        case loading
        case noAccount(message: String, amountToCreate: Decimal)
        case failed(error: String)

        var isLoading: Bool {
            switch self {
            case .loading, .created:
                return true
            default:
                return false
            }
        }

        var isBlockchainUnreachable: Bool {
            switch self {
            case .failed:
                return true
            default:
                return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .failed(let localizedDescription):
                return localizedDescription
            case .noAccount(let message, _):
                return message
            default:
                return nil
            }
        }

        var failureDescription: String? {
            switch self {
            case .failed(let localizedDescription):
                return localizedDescription
            default:
                return nil
            }
        }

        var description: String {
            switch self {
            case .created: "Created"
            case .loaded: "Loaded"
            case .loading: "Loading"
            case .noAccount(let message, _): "No account \(message)"
            case .failed(let error): "Failed \(error)"
            }
        }

        fileprivate var canCreateOrPurgeWallet: Bool {
            switch self {
            case .failed, .loading, .created:
                return false
            case .noAccount, .loaded:
                return true
            }
        }
    }

    enum WalletManagerUpdateResult: Hashable {
        case success
        case noAccount(message: String)
    }
}
