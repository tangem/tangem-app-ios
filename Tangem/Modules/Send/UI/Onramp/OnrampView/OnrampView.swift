//
//  OnrampView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampView: View {
    @ObservedObject var viewModel: OnrampViewModel

    let transitionService: SendTransitionService
    let namespace: Namespace

    var body: some View {
        GroupedScrollView(spacing: 14) {
            OnrampAmountView(
                viewModel: viewModel.onrampAmountViewModel,
                namespace: .init(id: namespace.id, names: namespace.names)
            )
        }
    }
}

extension OnrampView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendSummaryViewGeometryEffectNames
    }
}
