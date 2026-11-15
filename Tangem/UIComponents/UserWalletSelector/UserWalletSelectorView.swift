//
//  UserWalletSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemLocalization

struct UserWalletSelectorView: View {
    @ObservedObject private var viewModel: UserWalletSelectorViewModel

    init(viewModel: UserWalletSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        UserWalletSelectorList(items: viewModel.items, isBalanceMasked: viewModel.isBalanceMasked, onTap: viewModel.select)
            .padding(.horizontal, 16)
            .selectorUnavailableAlert($viewModel.unavailableReason)
    }
}

extension View {
    func selectorUnavailableAlert(_ reason: Binding<SelectorUnavailableReason?>) -> some View {
        alert(
            reason.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { reason.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        reason.wrappedValue = nil
                    }
                }
            ),
            actions: {
                SwiftUI.Button(Localization.commonGotIt) {}
            },
            message: {
                Text(reason.wrappedValue?.message ?? "")
            }
        )
    }
}
