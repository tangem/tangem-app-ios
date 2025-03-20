//
//  WalletConnectV2Factory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OldWalletConnectFactory {
    func createWCService() -> OldWalletConnectV2Service {
        let uiDelegate = WalletConnectAlertUIDelegate()
        let messageComposer = WalletConnectV2MessageComposer()
        let ethTransactionBuilder = CommonWalletConnectEthTransactionBuilder()

        let handlersFactory = WalletConnectHandlersFactory(
            messageComposer: messageComposer,
            uiDelegate: uiDelegate,
            ethTransactionBuilder: ethTransactionBuilder
        )
        let wcHandlersService = WalletConnectV2HandlersService(
            uiDelegate: uiDelegate,
            handlersCreator: handlersFactory
        )
        let v2Service = OldWalletConnectV2Service(
            uiDelegate: uiDelegate,
            messageComposer: messageComposer,
            wcHandlersService: wcHandlersService
        )

        return v2Service
    }
}
