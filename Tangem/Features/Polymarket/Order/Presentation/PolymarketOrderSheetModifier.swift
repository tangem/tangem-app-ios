//
//  PolymarketOrderSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PolymarketOrderSheetModifier: ViewModifier {
    @ObservedObject var presenter: PolymarketOrderPresenter

    let host: AnyObject?

    func body(content: Content) -> some View {
        content
            .sheet(item: presenter.binding(for: host), onDismiss: presenter.didDismiss) { orderCoordinator in
                NavigationStack {
                    PolymarketOrderCoordinatorView(coordinator: orderCoordinator)
                }
                .presentationCornerRadius(presentationCornerRadius(for: orderCoordinator))
                .containerCornerRadius(presentationCornerRadius(for: orderCoordinator) ?? Constants.cornerRadius)
                .background {
                    if let mainCoordinator = presenter.mainCoordinator {
                        PolymarketMainSheetHost(coordinator: mainCoordinator, isActive: true)
                    }
                }
                .softTopScrollEdgeEffect()
            }
    }

    private func presentationCornerRadius(for coordinator: PolymarketOrderCoordinator) -> CGFloat? {
        coordinator.flowStyle.isSingleSheet ? ModalAppearance.cornerRadius : Constants.cornerRadius
    }
}

extension View {
    @ViewBuilder
    func polymarketOrderSheet(presenter: PolymarketOrderPresenter?, host: AnyObject?) -> some View {
        if let presenter {
            modifier(PolymarketOrderSheetModifier(presenter: presenter, host: host))
        } else {
            self
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 24
}
