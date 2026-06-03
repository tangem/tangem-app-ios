//
//  AddTokenFlowRedesignedRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol AddTokenFlowRedesignedRoutable: AnyObject {
    func close()
    func presentSuccessToast(with text: String)
    func presentErrorToast(with text: String)
}
