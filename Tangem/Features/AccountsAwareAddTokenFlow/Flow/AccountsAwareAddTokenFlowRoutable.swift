//
//  AccountsAwareAddTokenFlowRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol AccountsAwareAddTokenFlowRoutable: AnyObject {
    @MainActor
    func close()
    func presentSuccessToast(with text: String)
    func presentErrorToast(with text: String)
}
