//
//  SendAmountCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct SendAmountCompactView: View {
    let viewModel: SendAmountCompactViewModel
    let type: SendCompactViewEditableType
    let namespace: SendAmountView.Namespace

    var body: some View {
        GroupedSection(viewModel) { _ in
            amountContent
        }
        .innerContentPadding(16)
        .backgroundColor(type.background)
        .geometryEffect(.init(id: namespace.names.amountContainer, namespace: namespace.id))
        .readGeometry(\.size, onChange: { viewModel.viewSize = $0 })
        .contentShape(Rectangle())
        .onTapGesture {
            if case .enabled(.some(let action)) = type {
                action()
            }
        }
    }

    @ViewBuilder
    private var amountContent: some View {
        switch viewModel.conventViewModel {
        case .default(let viewModel):
            SendAmountCompactContentView(viewModel: viewModel, namespace: namespace)
        case .nft(let viewModel):
            NFTSendAmountCompactContentView(viewModel: viewModel, borderColor: type.background)
        }
    }
}
