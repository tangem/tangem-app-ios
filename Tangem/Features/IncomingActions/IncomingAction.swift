//
//  IncomingAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum IncomingAction: Equatable {
    case walletConnect(WalletConnectRequestURI)
    case start // Run scan or request biometrics
    case dismissSafari(URL)
    case referralProgram
    case navigation(NavigationAction)
}

public enum NavigationAction: Equatable {
    case main
    case token(tokenName: String, network: String?)
    case referral
    case buy
    case sell
    case markets
    case tokenChart(tokenName: String)
    case staking(tokenName: String)
}
