//
//  PreserveRule+walletConnectDeeplink.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves only the WalletConnect topic embedded into Tangem deeplinks so
    /// broad hex redaction can still redact sensitive query values like `symKey`, for example:
    /// `tangem://wc?uri=wc%3A08018d08454c05ed4a5714cf74df3279f95648a9c216b68380599f9120a03a68%402%3FexpiryTimestamp%3D1777542409%26relay-protocol%3Dirn%26symKey%3Da5f72962c597402f36964378228212aad395b1fb705f6259ae6bf96aef944c40`
    static let walletConnectDeeplink = PreserveRule(
        placeholderPrefix: "WC_DEEPLINK",
        pattern: Self.walletConnectDeeplinkPattern
    )
}

private extension PreserveRule {
    static let walletConnectDeeplinkPattern = Regex {
        deeplinkPrefix
        encodedTopic
        Lookahead {
            encodedAt
        }
    }

    /// Matches the encoded WalletConnect topic until the encoded version separator `%40`.
    static let encodedTopic = Regex {
        OneOrMore {
            NegativeLookahead {
                encodedAt
            }
            CharacterClass.any
        }
    }

    static let deeplinkPrefix = "tangem://wc?uri=wc%3A"
    static let encodedAt = "%40"
}
