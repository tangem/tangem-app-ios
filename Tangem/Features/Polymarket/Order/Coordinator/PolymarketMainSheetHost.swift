//
//  PolymarketMainSheetHost.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PolymarketMainSheetHost: View {
    @ObservedObject var coordinator: PolymarketCoordinator

    let isActive: Bool

    var body: some View {
        Color.clear
            .sheet(item: isActive ? $coordinator.sheet : .constant(nil)) { sheet in
                switch sheet {
                case .send(let sendCoordinator):
                    SendCoordinatorView(coordinator: sendCoordinator)
                case .supportChat(let viewModel):
                    NavigationStack {
                        SupportChatView(viewModel: viewModel)
                            .toolbar {
                                NavigationToolbarButton.close(placement: .topBarLeading) { coordinator.sheet = nil }
                            }
                    }
                }
            }
    }
}
