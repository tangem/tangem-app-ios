//
//  WalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import SwiftUI
import TangemAssets
import TangemFoundation

struct WalletSelectorView: View {
    @ObservedObject var viewModel: WalletSelectorViewModel

    var body: some View {
        VStack {
            VStack {
                ForEach(viewModel.itemViewModels) { itemViewModel in
                    WalletSelectorItemView(viewModel: itemViewModel)
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: .zero)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationBarTitle(Text(Localization.manageTokensWalletSelectorTitle), displayMode: .inline)
    }
}

#Preview {
    final class PreviewWalletSelectorDataSource: WalletSelectorDataSource {
        var _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

        var itemViewModels: [WalletSelectorItemViewModel] = []
        var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
            _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
        }
    }

    return WalletSelectorView(
        viewModel: WalletSelectorViewModel(dataSource: PreviewWalletSelectorDataSource())
    )
}
