//
//  SupportTypeSelectionModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Drives the support-type selection sheet (email vs chat). Shared by flows that let
/// the user choose how to contact support (Settings, Swap).
struct SupportTypeSelectionModel: Identifiable {
    let id = UUID()
    let emailAction: () -> Void
    let chatAction: () -> Void
}
