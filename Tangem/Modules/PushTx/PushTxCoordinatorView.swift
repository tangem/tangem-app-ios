//
//  PushTxCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct PushTxCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PushTxCoordinator
    
    var body: some View {
        PushTxView(viewModel: coordinator.pushTxViewModel)
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
