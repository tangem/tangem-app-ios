//
//  PolymarketApprovalContracts.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PolymarketApprovalContracts {
    static let conditionalTokens = "0x4D97DCd97eC945f40cF65F87097ACe5EA0476045"
    static let ctfExchange = "0xE111180000d2663C0091e4f400237545B87B996B"
    static let negRiskCtfExchange = "0xe2222d279d744050d28e00520010520000310F59"
    static let negRiskAdapter = "0xd91E80cF2E7be2e162c6513ceD06f1dD0dA35296"
    static let ctfCollateralAdapter = "0xAdA100Db00Ca00073811820692005400218FcE1f"
    static let negRiskCtfCollateralAdapter = "0xadA2005600Dec949baf300f4C6120000bDB6eAab"

    /// Named after the BFF contract. Polymarket's own docs list the first one under Combos, as the
    /// `Exchange` proxy, and do not list the second at all — rename here only together with the contract.
    static let exchangeV3 = "0xe3333700cA9d93003F00f0F71f8515005F6c00Aa"
    static let routerV3 = "0x12121212006e4CD160D18e3f00711DA5c3372600"
}
