//
//  WalletConnectV2HandlersFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwiftV2

struct WalletConnectHandlersFactory {
    private let messageComposer: WalletConnectV2MessageComposable
    private let uiDelegate: WalletConnectUIDelegate

    init(
        messageComposer: WalletConnectV2MessageComposable,
        uiDelegate: WalletConnectUIDelegate
    ) {
        self.messageComposer = messageComposer
        self.uiDelegate = uiDelegate
    }

    func createHandler(for action: WalletConnectAction, with params: AnyCodable, using signer: TangemSigner, and walletModel: WalletModel) throws -> WalletConnectMessageHandler {
        let wcSigner = WalletConnectSigner(walletModel: walletModel, signer: signer)
        switch action {
        case .personalSign:
            return try WalletConnectV2PersonalSignHandler(
                request: params,
                using: wcSigner
            )
        case .signTypedData, .signTypedDataV4:
            return try WalletConnectV2SignTypedDataHandler(
                requestParams: params,
                signer: wcSigner
            )
        case .signTransaction:
            fallthrough
        case .sendTransaction:
            throw WalletConnectV2Error.unknown("Not implemented")
        case .bnbSign, .bnbTxConfirmation:
            // [REDACTED_TODO_COMMENT]
            // Initially this methods was found occasionally and supported without any request
            // Need to find documentation and find place where it can be tested on 2.0
            // This page https://www.bnbchain.org/en/staking has WalletConnect in status 'Coming Soon'
            throw WalletConnectV2Error.unsupportedWCMethod("BNB methods")
        case .switchChain:
            throw WalletConnectV2Error.unsupportedWCMethod("Switch chain for WC 2.0")
        }
    }
}
