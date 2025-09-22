//
//  SendDestinationCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUIUtils
import TangemUI

struct SendDestinationCompactView: View {
    @ObservedObject var viewModel: SendDestinationCompactViewModel

    let type: SendCompactViewEditableType

    var body: some View {
        GroupedSection(viewModel.destinationViewTypes) { type in
            switch type {
            case .address(let address, let corners):
                SendDestinationAddressSummaryView(
                    addressTextViewHeightModel: viewModel.addressTextViewHeightModel,
                    address: address
                )
                .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                .background(
                    self.type.background
                        .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: corners)
                )
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
                    .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                    .background(
                        self.type.background
                            .cornerRadius(GroupedSectionConstants.defaultCornerRadius, corners: [.bottomLeft, .bottomRight])
                    )
            }
        }
        .horizontalPadding(0)
        .separatorStyle(.minimum)
        .settings(\.backgroundColor, .clear)
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
        .contentShape(Rectangle())
        .onTapGesture {
            if case .enabled(.some(let action)) = type {
                action()
            }
        }
    }
}
