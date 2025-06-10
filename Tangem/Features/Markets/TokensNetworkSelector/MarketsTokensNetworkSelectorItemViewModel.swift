//
//  MarketsTokensNetworkSelectorItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

class MarketsTokensNetworkSelectorItemViewModel: Identifiable, ObservableObject {
    @Published var isSelected: Bool = false

    let id: UUID = .init()

    let tokenItem: TokenItem
    let position: ItemPosition
    let isMain: Bool
    let networkName: String
    let contractName: String?

    var isReadonly: Bool

    var networkNameForegroundColor: Color {
        guard !isReadonly else {
            return Colors.Text.disabled
        }

        return isSelected ? Colors.Text.primary1 : Colors.Text.secondary
    }

    var contractNameForegroundColor: Color {
        guard !isReadonly else {
            return Colors.Text.disabled
        }

        return tokenItem.isBlockchain ? Colors.Text.accent : Colors.Text.tertiary
    }

    var checkedImage: Image {
        guard !isReadonly else {
            return Assets.Checked.disabled.image
        }

        return isSelected ? Assets.Checked.on.image : Assets.Checked.off.image
    }

    var iconImageAsset: ImageType {
        guard !isReadonly else {
            return imageAsset
        }

        return isSelected ? imageAssetSelected : imageAsset
    }

    private var isSelectedBinding: Binding<Bool>
    private var bag = Set<AnyCancellable>()

    private let imageAsset: ImageType
    private let imageAssetSelected: ImageType

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        isReadonly: Bool,
        isSelected: Binding<Bool>,
        position: ItemPosition = .middle,
        blockchainIconProvider: NetworkImageProvider = NetworkImageProvider()
    ) {
        self.tokenItem = tokenItem
        self.isReadonly = isReadonly
        isSelectedBinding = isSelected
        self.position = position
        isMain = tokenItem.isBlockchain
        imageAsset = blockchainIconProvider.provide(by: tokenItem.blockchain, filled: false)
        imageAssetSelected = blockchainIconProvider.provide(by: tokenItem.blockchain, filled: true)
        networkName = tokenItem.blockchain.displayName
        contractName = tokenItem.contractName

        self.isSelected = isSelected.wrappedValue

        $isSelected
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, value in
                viewModel.isSelectedBinding.wrappedValue = value
            })
            .store(in: &bag)
    }

    func updateSelection(with isSelected: Binding<Bool>, isReadonly: Bool) {
        isSelectedBinding = isSelected
        self.isReadonly = isReadonly
        self.isSelected = isSelected.wrappedValue
    }
}
