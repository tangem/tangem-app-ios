//
//  ManageTokensNetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import AlertToast

struct ManageTokensNetworkSelectorView: View {
    @ObservedObject var viewModel: ManageTokensNetworkSelectorViewModel

    var body: some View {
        ZStack {
            list

            overlay
        }
        .scrollDismissesKeyboardCompat(true)
        .alert(item: $viewModel.alert, content: { $0.alert })

        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
    }

    private var list: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.selectorItems) {
                    ManageTokensNetworkSelectorItemView(viewModel: $0)
                }

                Color.clear.frame(width: 10, height: 58, alignment: .center)
            }
        }
    }

    @ViewBuilder private var overlay: some View {
        VStack {
            Spacer()

            MainButton(
                title: Localization.commonSaveChanges,
                isLoading: false,
                isDisabled: viewModel.isSaveDisabled,
                action: viewModel.saveChanges
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(LinearGradient(
                colors: [Colors.Background.primary, Colors.Background.primary, Colors.Background.primary.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .edgesIgnoringSafeArea(.bottom))
        }
    }
}
