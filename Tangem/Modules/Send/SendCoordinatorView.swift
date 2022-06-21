//
//  SendCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SendCoordinator
    
    var body: some View {
        ZStack {
            SendView(viewModel: coordinator.sendViewModel)
            
            sheets
        }
    }
    
    @ViewBuilder
    private var sheets: some View {
        VStack {
            SheetHolder()
                .sheet(item: $coordinator.mailViewModel) {
                    MailView(viewModel: $0)
                }
            
            SheetHolder()
                .sheet(item: $coordinator.qrScanViewModel) {
                    QRScanView(viewModel: $0)
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
}
