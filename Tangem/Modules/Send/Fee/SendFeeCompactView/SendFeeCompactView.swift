//
//  SendFeeCompactView.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendFeeCompactView: View {
    @ObservedObject var viewModel: SendFeeCompactViewModel
    let namespace: SendFeeView.Namespace

    var body: some View {
        GroupedSection(viewModel.selectedFeeRowViewModel) { feeRowViewModel in
            FeeRowView(viewModel: feeRowViewModel)
                .setNamespace(namespace.id)
                .setOptionNamespaceId(namespace.names.feeOption(feeOption: feeRowViewModel.option))
                .setAmountNamespaceId(namespace.names.feeAmount(feeOption: feeRowViewModel.option))
                .disabled(true)
        } header: {
            DefaultHeaderView(Localization.commonNetworkFeeTitle)
                .matchedGeometryEffect(id: namespace.names.feeTitle, in: namespace.id)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .geometryEffect(.init(id: namespace.names.feeContainer, namespace: namespace.id))
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
    }
}
