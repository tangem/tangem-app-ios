//
//  WalletConnectDisconnectDAppService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectDisconnectDAppService {
    func disconnect(with sessionTopic: String) async throws
}
