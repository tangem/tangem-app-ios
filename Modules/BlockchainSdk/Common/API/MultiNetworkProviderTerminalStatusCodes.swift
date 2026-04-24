//
//  MultiNetworkProviderTerminalStatusCodes.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

typealias MultiNetworkProviderTerminalStatusCodes = [MultiNetworkProviderStatusCodes]

enum MultiNetworkProviderStatusCodes {
    case success
    case redirect
    case clientError
    case serverError

    func contains(_ code: Int) -> Bool {
        switch self {
        case .success:
            return (200 ... 299).contains(code)
        case .redirect:
            return (300 ... 399).contains(code)
        case .clientError:
            return (400 ... 499).contains(code)
        case .serverError:
            return (500 ... 599).contains(code)
        }
    }
}

extension MultiNetworkProviderTerminalStatusCodes {
    func shouldStopSwitching(_ code: Int) -> Bool {
        contains(where: { $0.contains(code) })
    }
}

// MARK: - Convenient options

extension MultiNetworkProviderTerminalStatusCodes {
    /// Any status code will allow switch to next provider
    static let empty: Self = []
    static let failure: Self = [.clientError, .serverError]
}
