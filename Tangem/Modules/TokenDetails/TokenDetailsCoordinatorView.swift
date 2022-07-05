//
//  TokenDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TokenDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TokenDetailsCoordinator
    
    var body: some View {
        ZStack {
            if let model = coordinator.tokenDetailsViewModel {
                TokenDetailsView(viewModel: model)
                    .navigationLinks(links)
                
                BottomSheetView(isPresented: coordinator.$showWarning,
                                showClosedButton: false,
                                addDragGesture: false,
                                closeOnTapOutside: false,
                                cornerRadius: 30) {
                } content: {
                    WarningBankCardView {
                        coordinator.warningBankCardViewModel?.confirmCallback()
                        coordinator.showWarning = false
                    } decline: {
                        coordinator.warningBankCardViewModel?.declineCallback()
                        coordinator.showWarning = false
                    }
                }
            }
            
            sheets
        }
    }
    
    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .emptyNavigationLink()
    }
    
    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
        
        NavHolder()
            .sheet(item: $coordinator.pushTxCoordinator) {
                PushTxCoordinatorView(coordinator: $0)
            }
        
        NavHolder()
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
        
        NavHolder()
            .sheet(item: $coordinator.p2pTutorialWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
    }
}
