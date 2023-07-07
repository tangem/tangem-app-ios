//
//  WalletConnectV2Factory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

typealias WCServices = (v1Service: WalletConnectV1Service, v2Service: WalletConnectV2Service)

struct WalletConnectFactory {
    func createWCServices(for model: CardViewModel) -> WCServices {
        let v1Service = WalletConnectV1Service(with: model)
        let uiDelegate = WalletConnectAlertUIDelegate()
        let messageComposer = WalletConnectV2MessageComposer()
        let ethTransactionBuilder = CommonWalletConnectEthTransactionBuilder()

        let handlersFactory = WalletConnectHandlersFactory(
            signer: model.signer,
            messageComposer: messageComposer,
            uiDelegate: uiDelegate,
            ethTransactionBuilder: ethTransactionBuilder
        )
        let wcHandlersService = WalletConnectV2HandlersService(
            uiDelegate: uiDelegate,
            handlersCreator: handlersFactory
        )
        let v2Service = WalletConnectV2Service(
            with: model,
            uiDelegate: uiDelegate,
            messageComposer: messageComposer,
            wcHandlersService: wcHandlersService
        )

        handlersFactory.walletModelProvider = v2Service
        return (v1Service, v2Service)
    }
}
