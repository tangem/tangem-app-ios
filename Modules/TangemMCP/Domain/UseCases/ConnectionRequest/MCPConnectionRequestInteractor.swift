//
//  MCPConnectionRequestInteractor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct MCPConnectionRequestInteractor: Sendable {
    let fetchRequest: FetchMCPConnectionRequestUseCase
    let reject: RejectMCPConnectionUseCase
    let accept: AcceptMCPConnectionUseCase
}
