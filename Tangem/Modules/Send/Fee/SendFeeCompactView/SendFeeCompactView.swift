//
//  SendFeeCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendFeeCompactView: View {
    @ObservedObject var viewModel: SendFeeCompactViewModel
    let namespace: SendFeeView.Namespace
    let tapAction: () -> Void

    var body: some View {
        GroupedSection(viewModel.selectedFeeRowViewModel) { feeRowViewModel in
            FeeRowView(viewModel: feeRowViewModel)
                .optionGeometryEffect(
                    .init(
                        id: namespace.names.feeOption(feeOption: feeRowViewModel.option),
                        namespace: namespace.id
                    )
                )
                .amountGeometryEffect(
                    .init(
                        id: namespace.names.feeAmount(feeOption: feeRowViewModel.option),
                        namespace: namespace.id
                    )
                )
        } header: {
            DefaultHeaderView(Localization.commonNetworkFeeTitle)
                .matchedGeometryEffect(id: namespace.names.feeTitle, in: namespace.id)
                .padding(.top, 12)
        }
        .backgroundColor(Colors.Background.action)
        .geometryEffect(.init(id: namespace.names.feeContainer, namespace: namespace.id))
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
        .contentShape(Rectangle())
        .allowsHitTesting(viewModel.canEditFee)
        .onTapGesture {
            tapAction()
        }
    }
}
