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
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: PromocodeActivationViewModel

    init(promoCode: String) {
        _viewModel = StateObject(wrappedValue: PromocodeActivationViewModel(promoCode: promoCode))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            ProgressView().progressViewStyle(.circular)
        }
        .task {
            await viewModel.start()
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.isPresentingAlert) {
            Button(Localization.commonOk, role: .cancel) {
                dismiss()
//                viewModel.dismissSelf()
            }
        }
    }
}

#Preview {
    PromocodeActivationView(promoCode: "")
}
