//
//  PromocodeActivationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

struct PromocodeActivationView: View {
    @StateObject var viewModel: PromocodeActivationViewModel

    init(promoCode: String, refcode: String?, campaign: String?) {
        _viewModel = StateObject(wrappedValue: PromocodeActivationViewModel(promoCode: promoCode, refcode: refcode, campaign: campaign))
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.4)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .opacity(viewModel.isCheckingPromoCode ? 1 : 0)
        }
        .task {
            await viewModel.activatePromoCode()
        }
        .alert(item: $viewModel.alert) { $0.alert }
    }
}
