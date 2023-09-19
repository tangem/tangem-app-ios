//
//  AddCustomTokenDerivationPathSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct AddCustomTokenDerivationPathSelectorView: View {
    @ObservedObject private var viewModel: AddCustomTokenDerivationPathSelectorViewModel

    init(viewModel: AddCustomTokenDerivationPathSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: viewModel.customDerivationOption, isSelected: true, didTapOption: {}))
                    .background(Colors.Background.action)
                    .cornerRadiusContinuous(14)
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(viewModel.derivationOptions, id: \.id) { derivationOption in

                        AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: derivationOption, isSelected: false, didTapOption: {}))

//                        if viewModel.derivationOptions.last != derivationOption {
                        Separator(height: 0.5, padding: 0, color: Colors.Stroke.primary)
                            .padding(.leading, 16)
//                        }
                    }
                }
                .background(Colors.Background.action)
                .cornerRadiusContinuous(14)
                .padding(.horizontal, 16)
                // [REDACTED_TODO_COMMENT]
            }
        }
        .background(Colors.Background.tertiary.ignoresSafeArea())
    }
}

struct AddCustomTokenDerivationPathSelectorView_Preview: PreviewProvider {
    static let viewModel = AddCustomTokenDerivationPathSelectorViewModel(
        selectedDerivationOption: .custom(derivationPath: nil),
        defaultDerivationPath: try! DerivationPath(rawPath: "m/44’/0’/0’/0’/0’"),
        blockchainDerivationOptions: SupportedBlockchains.all.map {
            AddCustomTokenDerivationOption.blockchain(
                name: $0.displayName,
                derivationPath: $0.derivationPath(for: .v1) ?? (try! DerivationPath(rawPath: "m/44’/0’/0’/0’/0’"))
            )
        },
        coordinator: AddCustomTokenDerivationPathSelectorCoordinator()
    )

    static var previews: some View {
        AddCustomTokenDerivationPathSelectorView(viewModel: viewModel)
    }
}
