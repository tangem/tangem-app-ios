//
//  AccountPickerViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAccounts
import TangemFoundation
import TangemLocalization

// [REDACTED_TODO_COMMENT]
@MainActor
final class AccountPickerViewModel: ObservableObject {
    @Injected(\.cryptoAccountsGlobalStateProvider)
    private static var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    @Published private(set) var title: String
    @Published private(set) var content: Content
    @Published private(set) var isBalanceMasked: Bool

    let showsSelectionCheckmarks: Bool

    private var presentation: Presentation
    private let accountAvailabilityProvider: any AccountPickerAccountAvailabilityProvider
    private let userWalletAvailabilityProvider: any UserWalletSelectorAvailabilityProvider
    private let onSelect: (AccountPickerSelection) -> Void
    private let onUnavailableSelect: (AccountPickerSelection, SelectorUnavailableReason) -> Void
    private let userWalletItemsStore = UserWalletSelectorItemsStore()

    private var userWallets: [AccountPickerUserWallet] = []
    private var selectedAccountId: AnyHashable?
    private var accountDetails: [AnyHashable: AccountDetails] = [:]
    private var trackedAccountIds: Set<AnyHashable> = []
    private var bag = Set<AnyCancellable>()

    init(
        userWalletsProvider: some AccountPickerUserWalletsProvider,
        accountAvailabilityProvider: any AccountPickerAccountAvailabilityProvider = .allAvailable(),
        userWalletAvailabilityProvider: any UserWalletSelectorAvailabilityProvider = .lockState(),
        selectedAccount: (any BaseAccountModel)? = nil,
        onSelect: @escaping (AccountPickerSelection) -> Void,
        onUnavailableSelect: @escaping (AccountPickerSelection, SelectorUnavailableReason) -> Void = { _, _ in }
    ) {
        let presentation = Presentation(Self.cryptoAccountsGlobalStateProvider.globalCryptoAccountsState())

        self.presentation = presentation
        title = presentation.title
        content = presentation.emptyContent
        self.accountAvailabilityProvider = accountAvailabilityProvider
        self.userWalletAvailabilityProvider = userWalletAvailabilityProvider
        self.onSelect = onSelect
        self.onUnavailableSelect = onUnavailableSelect
        selectedAccountId = selectedAccount?.id.toAnyHashable()
        showsSelectionCheckmarks = selectedAccount != nil
        isBalanceMasked = SensitiveTextVisibilityViewModel.shared.isHidden

        bind(userWalletsProvider: userWalletsProvider)
    }

    func select(_ item: UserWalletSelectorItem) {
        guard
            let userWallet = userWallets.first(where: { $0.userWalletModel.userWalletId == item.id }),
            let account = userWallet.accounts.first
        else {
            return
        }

        select(account: account, in: userWallet.userWalletModel)
    }

    func select(_ item: AccountPickerAccountItem) {
        for userWallet in userWallets {
            if let account = userWallet.accounts.first(where: { $0.id.toAnyHashable() == item.id }) {
                select(account: account, in: userWallet.userWalletModel)
                return
            }
        }
    }
}

// MARK: - Content

extension AccountPickerViewModel {
    enum Content {
        case userWallets([UserWalletSelectorItem])
        case accounts([AccountPickerUserWalletSection])
    }
}

// MARK: - Private

private extension AccountPickerViewModel {
    enum Presentation {
        case userWallets
        case accounts

        init(_ state: CryptoAccounts.State) {
            self = state == .single ? .userWallets : .accounts
        }

        var title: String {
            switch self {
            case .userWallets: Localization.commonChooseWallet
            case .accounts: Localization.commonChooseAccount
            }
        }

        var emptyContent: Content {
            switch self {
            case .userWallets: .userWallets([])
            case .accounts: .accounts([])
            }
        }
    }

    struct AccountDetails {
        let tokensCount: String
        let balance: SelectorBalance
    }

    func bind(userWalletsProvider: some AccountPickerUserWalletsProvider) {
        userWalletItemsStore.onChange = { [weak self] in
            self?.rebuildContent()
        }

        userWalletsProvider.userWalletsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, userWallets in
                viewModel.update(userWallets: userWallets)
            }
            .store(in: &bag)

        Self.cryptoAccountsGlobalStateProvider.globalCryptoAccountsStatePublisher()
            .map(Presentation.init)
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, presentation in
                viewModel.update(presentation: presentation)
            }
            .store(in: &bag)

        SensitiveTextVisibilityViewModel.shared.$isHidden
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isHidden in
                viewModel.isBalanceMasked = isHidden
            }
            .store(in: &bag)
    }

    func update(presentation: Presentation) {
        guard presentation != self.presentation else {
            return
        }

        self.presentation = presentation
        title = presentation.title
        update(userWallets: userWallets)
    }

    func update(userWallets: [AccountPickerUserWallet]) {
        self.userWallets = userWallets

        switch presentation {
        case .userWallets:
            userWalletItemsStore.track(userWallets.map(\.userWalletModel))
        case .accounts:
            userWallets.flatMap(\.accounts).forEach(trackDetails(of:))
        }

        rebuildContent()
    }

    func rebuildContent() {
        switch presentation {
        case .userWallets:
            content = .userWallets(userWallets.compactMap(makeUserWalletItem))
        case .accounts:
            content = .accounts(makeSections())
        }
    }

    func makeUserWalletItem(_ userWallet: AccountPickerUserWallet) -> UserWalletSelectorItem? {
        let userWalletModel = userWallet.userWalletModel
        let userWalletAvailability = userWalletAvailabilityProvider.availability(of: userWalletModel)

        if userWalletAvailability == .locked {
            return userWalletItemsStore.item(for: userWalletModel, availability: .locked)
        }

        guard let account = userWallet.accounts.first else {
            return nil
        }

        return userWalletItemsStore.item(for: userWalletModel, availability: availability(of: account, in: userWalletModel))
    }

    func makeSections() -> [AccountPickerUserWalletSection] {
        let visibleUserWallets = userWallets.filter { userWallet in
            userWallet.accounts.isNotEmpty && userWalletAvailabilityProvider.availability(of: userWallet.userWalletModel) != .locked
        }
        let showsHeaders = visibleUserWallets.count > 1

        return visibleUserWallets.map { userWallet in
            let userWalletModel = userWallet.userWalletModel

            return AccountPickerUserWalletSection(
                id: userWalletModel.userWalletId.stringValue,
                header: showsHeaders
                    ? AccountPickerUserWalletSection.Header(name: userWalletModel.name, thumbnail: userWalletModel.config.walletThumbnailType)
                    : nil,
                accounts: userWallet.accounts.map { makeAccountItem(account: $0, userWalletModel: userWalletModel) }
            )
        }
    }

    func makeAccountItem(account: any BaseAccountModel, userWalletModel: any UserWalletModel) -> AccountPickerAccountItem {
        let id = account.id.toAnyHashable()
        let details = accountDetails[id]
        let cryptoAccount = account as? any CryptoAccountModel
        let isJoint = cryptoAccount?.accountType == .joint
        let placeholderBalance: SelectorBalance? = cryptoAccount == nil ? nil : .loading(cached: nil)
        let availability = availability(of: account, in: userWalletModel)

        return AccountPickerAccountItem(
            id: id,
            name: account.name,
            icon: AccountModelUtils.UI.avatarAccount(accountModel: account),
            badge: isJoint ? Localization.commonJoint : nil,
            subtitle: details.map { "\($0.tokensCount) \(AppConstants.dotSign)" },
            balance: details?.balance ?? placeholderBalance,
            availability: availability,
            isSelected: id == selectedAccountId && availability.isAvailable
        )
    }

    func availability(of account: any BaseAccountModel, in userWalletModel: any UserWalletModel) -> SelectorAvailability {
        let userWalletAvailability = userWalletAvailabilityProvider.availability(of: userWalletModel)

        guard userWalletAvailability == .available else {
            return userWalletAvailability
        }

        return accountAvailabilityProvider.availability(of: account, in: userWalletModel)
    }

    func trackDetails(of account: any BaseAccountModel) {
        let id = account.id.toAnyHashable()

        guard trackedAccountIds.insert(id).inserted else {
            return
        }

        account.didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.rebuildContent()
            }
            .store(in: &bag)

        guard let cryptoAccount = account as? any CryptoAccountModel else {
            return
        }

        cryptoAccount.userTokensManager.userTokensPublisher
            .map(\.count)
            .combineLatest(cryptoAccount.fiatTotalBalanceProvider.totalBalancePublisher.withAppCurrencyCode())
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (tokensCount, (state, currencyCode)) = input
                viewModel.accountDetails[id] = AccountDetails(
                    tokensCount: Localization.commonTokensCount(tokensCount),
                    balance: SelectorBalanceBuilder.build(state: state, currencyCode: currencyCode)
                )
                viewModel.rebuildContent()
            }
            .store(in: &bag)
    }

    func select(account: any BaseAccountModel, in userWalletModel: any UserWalletModel) {
        let selection = AccountPickerSelection(account: account, userWalletModel: userWalletModel)

        switch availability(of: account, in: userWalletModel) {
        case .available:
            selectedAccountId = account.id.toAnyHashable()
            rebuildContent()
            onSelect(selection)
        case .locked:
            break
        case .unavailable(let reason):
            onUnavailableSelect(selection, reason)
        }
    }
}

// MARK: - Equatable

extension AccountPickerViewModel: @MainActor Equatable {
    static func == (lhs: AccountPickerViewModel, rhs: AccountPickerViewModel) -> Bool {
        lhs === rhs
    }
}
