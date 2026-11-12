//
//  AllServicesItemsProvider.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets
import TangemLocalization

struct AllServicesItemsProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var actions: [AllServicesAction] {
        FeatureProvider.isAvailable(.mobileWalletMultiCreation)
            ? [Self.addWalletAction, Self.buyTangemAction]
            : [Self.buyTangemAction]
    }

    var itemsPublisher: AnyPublisher<[AllServicesItem], Never> {
        .just(output: fixedItems)
    }
}

// MARK: - Private

private extension AllServicesItemsProvider {
    var fixedItems: [AllServicesItem] {
        var items: [AllServicesItem] = []

        if hasAccountCapableWallet {
            items.append(Self.cryptoAccountItem)

            if FeatureProvider.isAvailable(.jointAccounts) {
                items.append(Self.jointAccountItem)
            }
        }

        return items
    }

    var hasAccountCapableWallet: Bool {
        UserWalletModelsProvider
            .available(from: userWalletRepository.models)
            .contains(where: \.accountModelsManager.canAddCryptoAccounts)
    }
}

// MARK: - Actions

private extension AllServicesItemsProvider {
    static var addWalletAction: AllServicesAction {
        AllServicesAction(
            id: .addWallet,
            icon: DesignSystem.Icons.SignPlus.regular20,
            title: Localization.userWalletAddWallet
        )
    }

    static var buyTangemAction: AllServicesAction {
        AllServicesAction(
            id: .buyTangem,
            icon: DesignSystem.Icons.LogoTangem.regular20,
            title: Localization.introductionButtonBuyTangem
        )
    }
}

// MARK: - Items

private extension AllServicesItemsProvider {
    static var cryptoAccountItem: AllServicesItem {
        AllServicesItem(
            id: .cryptoAccount,
            icon: .illustration(type: DesignSystem.Icons.accountCrypto, style: .brandFullTint),
            title: Localization.commonCryptoAccount,
            // [REDACTED_TODO_COMMENT]
            subtitle: "Separate funds by purpose"
        )
    }

    static var jointAccountItem: AllServicesItem {
        AllServicesItem(
            id: .jointAccount,
            icon: .illustration(type: DesignSystem.Icons.accountFamily, style: .brand),
            title: Localization.commonJointAccount,
            // [REDACTED_TODO_COMMENT]
            subtitle: "Share funds with group approvals"
        )
    }
}
