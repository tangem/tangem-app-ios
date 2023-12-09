//
//  WalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct WalletSelectorView: View {
    @ObservedObject var viewModel: WalletSelectorViewModel

    var body: some View {
        VStack {
            VStack {
                ForEach(viewModel.itemViewModels) { itemViewModel in
                    WalletSelectorItemView(viewModel: itemViewModel)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(14)
            .padding(16)

            Spacer()
        }
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationBarTitle(Text(Localization.manageTokensWalletSelectorTitle), displayMode: .inline)
    }
}

struct WalletSelectorView_Previews: PreviewProvider {
    private class PreviewWalletSelectorDataSource: WalletSelectorDataSource {
        private var _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

        var itemViewModels: [WalletSelectorItemViewModel] = []
        var selectedUserWalletModelPublisher: AnyPublisher<UserWalletId?, Never> {
            _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
        }
    }

    static var previews: some View {
        WalletSelectorView(
            viewModel: WalletSelectorViewModel(dataSource: PreviewWalletSelectorDataSource())
        )
    }
}
