//
//  TangemPayRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayRowViewModel: Identifiable {
    let id = UUID()

    let isKYCInProgress: Bool
    let tapAction: () -> Void
}
