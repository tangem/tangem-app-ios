//
//  WCFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct WCFactory {
    func createWCService() -> WCServiceV2 {
        // [REDACTED_TODO_COMMENT]
        let uiDelegate = WalletConnectAlertUIDelegate()
        let messageComposer = WalletConnectV2MessageComposer()
        let ethTransactionBuilder = CommonWalletConnectEthTransactionBuilder()

        let handlersFactory = WalletConnectHandlersFactory(
            messageComposer: messageComposer,
            uiDelegate: uiDelegate,
            ethTransactionBuilder: ethTransactionBuilder
        )
        let wcHandlersService = CommonWCHandlersService(wcHandlersFactory: handlersFactory)

        let v2Service = WCServiceV2(wcHandlersService: wcHandlersService)

        return v2Service
    }
}
