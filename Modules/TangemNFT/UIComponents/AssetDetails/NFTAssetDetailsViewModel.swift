//
//  NFTAssetDetailsViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI
import TangemLocalization
import TangemAssets
import TangemFoundation

public final class NFTAssetDetailsViewModel: ObservableObject, Identifiable {
    var name: String {
        asset.name
    }

    var media: NFTMedia? {
        NFTAssetMediaExtractor.extractMedia(from: asset)
    }

    var headerState: NFTDetailsHeaderState? {
        let priceWithDescription = makePriceWithDescription()
        let rarity = makeRarity(from: asset.rarity).nilIfEmpty

        switch (priceWithDescription, rarity) {
        case (.some(let priceWithDescription), .some(let rarity)):
            return .full(priceWithDescription, rarity)
        case (.some(let priceWithDescription), .none):
            return .priceWithDescription(priceWithDescription)
        case (.none, .some(let rarity)):
            return .rarity(rarity)
        case (.none, .none):
            return nil
        }
    }

    var traits: KeyValuePanelViewData? {
        guard asset.traits.isNotEmpty else {
            return nil
        }

        let maximumTraits = asset.traits.prefix(Constants.maximumTraits)

        let header = if asset.traits.count > Constants.maximumTraits {
            KeyValuePanelViewData.Header(
                title: Localization.nftDetailsTraits,
                actionConfig: KeyValuePanelViewData.Header.ActionConfig(
                    buttonTitle: Localization.commonSeeAll,
                    image: nil,
                    action: { [weak self] in self?.openAllTraits() }
                )
            )
        } else {
            KeyValuePanelViewData.Header(title: Localization.nftDetailsTraits, actionConfig: nil)
        }

        return KeyValuePanelViewData(
            header: header,
            keyValues: makeTraits(from: Array(maximumTraits))
        )
    }

    var baseInformation: KeyValuePanelViewData? {
        let header = KeyValuePanelViewData.Header(
            title: Localization.nftDetailsBaseInformation,
            actionConfig: KeyValuePanelViewData.Header.ActionConfig(
                buttonTitle: Localization.commonExplore,
                image: Assets.compassExplore,
                action: { [weak self] in self?.explore() }
            )
        )

        return KeyValuePanelViewData(header: header, keyValues: makeInfoKeyPairs())
    }

    private let asset: NFTAsset
    private let collection: NFTCollection
    private let nftChainNameProvider: NFTChainNameProviding
    private let priceFormatter: NFTPriceFormatting
    private let analytics: NFTAnalytics.Details

    @Published private var fiatPrice: LoadingResult<String, any Error> = .loading
    private var didAppear = false

    private weak var coordinator: NFTAssetDetailsRoutable?

    public init(
        asset: NFTAsset,
        collection: NFTCollection,
        dependencies: NFTAssetDetailsDependencies,
        coordinator: NFTAssetDetailsRoutable?
    ) {
        self.asset = asset
        self.collection = collection
        nftChainNameProvider = dependencies.nftChainNameProvider
        priceFormatter = dependencies.priceFormatter
        analytics = dependencies.analytics
        self.coordinator = coordinator
    }

    @MainActor
    func onViewAppear() {
        if didAppear {
            return
        }

        didAppear = true
        updateFiatPriceIfPossible()
    }

    func onSendButtonTap() {
        coordinator?.openSend(for: asset, in: collection)
        analytics.logSendTapped()
    }

    // MARK: Private implementation

    private func makeDescription() -> NFTDetailsHeaderState.DescriptionConfig? {
        guard let description = asset.description?.nilIfEmpty else {
            return nil
        }

        return NFTDetailsHeaderState.DescriptionConfig(
            text: description,
            readMoreAction: { [weak self] in self?.openDescription() }
        )
    }

    private func makePrice() -> NFTDetailsHeaderState.Price? {
        guard let salePrice = asset.salePrice?.last else {
            return nil
        }

        let cryptoPrice = priceFormatter.formatCryptoPrice(salePrice.value, in: asset.id.chain)

        return NFTDetailsHeaderState.Price(crypto: cryptoPrice, fiat: fiatPrice)
    }

    private func makePriceWithDescription() -> NFTDetailsHeaderState.PriceWithDescriptionState? {
        let description = makeDescription()
        let price = makePrice()

        switch (price, description) {
        case (.some(let price), .some(let description)):
            return .priceWithDescription(price, description)
        case (.some(let price), .none):
            return .price(price)
        case (.none, .some(let description)):
            return .description(description)
        case (.none, .none):
            return nil
        }
    }

    private func makeRarity(from rarity: NFTAsset.Rarity?) -> [KeyValuePairViewData] {
        guard let rarity else { return [] }

        let label = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsRarityLabel,
            value: rarity.label,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsRarityLabel,
                    text: Localization.nftDetailsInfoRarityLabel
                )
            }
        )

        let rankValue = rarity.rank
        let rank = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsRarityRank,
            value: rankValue?.description,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsRarityRank,
                    text: Localization.nftDetailsInfoRarityRank
                )
            }
        )

        return [
            label,
            rank,
        ].compactMap { $0 }
    }

    private func makeTokenStandard(from standard: NFTContractType) -> String? {
        switch standard {
        case .erc721:
            "ERC-721"
        case .erc1155:
            "ERC-1155"
        case .other(let string):
            string
        case .unknown, .analyticsOnly:
            nil
        }
    }

    /// Actions are under discussion, perhaps we wont do anything
    private func makeInfoKeyPairs() -> [KeyValuePairViewData] {
        let tokenStandard = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsTokenStandard,
            value: makeTokenStandard(from: asset.id.contractType),
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsTokenStandard,
                    text: Localization.nftDetailsInfoTokenStandard
                )
            }
        )

        let contractAddress = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsContractAddress,
            value: asset.id.contractAddress,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsContractAddress,
                    text: Localization.nftDetailsInfoContractAddress
                )
            }
        )

        let tokenID = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsTokenId,
            value: asset.id.identifier,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsTokenId,
                    text: Localization.nftDetailsInfoTokenId
                )
            }
        )

        let chain = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsChain,
            value: nftChainNameProvider.provide(for: asset.id.chain),
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsChain,
                    text: Localization.nftDetailsInfoChain
                )
            }
        )

        return [
            tokenStandard,
            contractAddress,
            tokenID,
            chain,
        ].compactMap { $0 }
    }

    private func makeTraits(from traits: [NFTAsset.Trait]) -> [KeyValuePairViewData] {
        traits.map {
            KeyValuePairViewData(
                key: KeyValuePairViewData.Key(text: $0.name, action: nil),
                value: KeyValuePairViewData.Value(text: $0.value, icon: nil)
            )
        }
    }

    private func makeKeyValuePairViewDataIfPossible(
        key: String,
        value: String?,
        action: @escaping () -> Void
    ) -> KeyValuePairViewData? {
        guard let value = value?.nilIfEmpty else { return nil }

        return KeyValuePairViewData(
            key: KeyValuePairViewData.Key(text: key, action: action),
            value: KeyValuePairViewData.Value(text: value, icon: nil)
        )
    }

    // MARK: Actions

    private func openAllTraits() {
        let traitsKeyValuePairs = makeTraits(from: asset.traits)
        coordinator?.openTraits(with: KeyValuePanelViewData(header: nil, keyValues: traitsKeyValuePairs))
        analytics.logSeeAllTapped()
    }

    private func explore() {
        coordinator?.openExplorer(for: asset)
        analytics.logExploreTapped()
    }

    private func openDescription() {
        guard let description = asset.description?.nilIfEmpty else { return }

        coordinator?.openInfo(
            with: NFTAssetExtendedInfoViewData(
                title: Localization.nftAboutTitle,
                text: description
            )
        )

        analytics.logReadMoreTapped()
    }

    private func openAssetExtendedInfo(title: String, text: String) {
        coordinator?.openInfo(with: NFTAssetExtendedInfoViewData(title: title, text: text))
    }

    @MainActor
    private func updateFiatPriceIfPossible() {
        guard let salePrice = asset.salePrice?.last else {
            return
        }

        runTask(in: self) { viewModel in
            let chain = viewModel.asset.id.chain
            let fiatPrice = await viewModel.priceFormatter.convertToFiatAndFormatCryptoPrice(salePrice.value, in: chain)
            // Since this is a non-detached task and inherits the Main Actor context, we can safely update the UI here
            viewModel.fiatPrice = .success(fiatPrice)
        }
    }
}

private extension NFTAssetDetailsViewModel {
    enum Constants {
        static let maximumTraits = 6
    }
}
