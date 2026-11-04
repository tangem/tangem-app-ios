//
//  ConnectionsRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.UUID
import enum TangemLocalization.Localization

struct ConnectionsRowViewModel: Identifiable {
    let id = UUID()
    let title = Localization.wcConnections
    let subtitle = Localization.wcConnectionsSubtitle
    let action: () -> Void
}
