//
//  ReferralViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import UIKit
import SwiftUI
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemAccounts
import struct TangemUIUtils.AlertBinder

final class ReferralViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var isProcessingRequest: Bool = false
    @Published var errorAlert: AlertBinder?
    @Published var expectedAwardsExpanded = false
    @Published private(set) var viewState: ViewState = .loading

    var mainButtonIcon: MainButton.Icon? {
        CommonTangemIconProvider(config: userWalletModel.config).getMainButtonIcon()
    }

    private weak var coordinator: ReferralRoutable?
    private let userWalletId: Data
    private let supportedBlockchains: Set<Blockchain>
    private let userWalletModel: UserWalletModel

    private let workMode: WorkMode
    private var accountModel: AccountModel?
    private var referralProgramInfo: ReferralProgramInfo?
    private let tokenIconInfoBuilder: TokenIconInfoBuilder
    private var bag = Set<AnyCancellable>()

    init(
        input: ReferralInputModel,
        coordinator: ReferralRoutable
    ) {
        userWalletId = input.userWalletId
        supportedBlockchains = input.supportedBlockchains
        self.coordinator = coordinator
        workMode = input.workMode
        tokenIconInfoBuilder = input.tokenIconInfoBuilder
        userWalletModel = input.userWalletModel

        runTask(in: self) { viewModel in
            await viewModel.fetchAndMapInitialState()
        }
    }

    @MainActor
    func fetchAndMapInitialState() async {
        switch workMode {
        case .plainUserTokensManager:
            let referralInfo = await loadReferralInfo()
            referralProgramInfo = referralInfo

            if referralInfo?.referral != nil {
                viewState = .loaded(.alreadyParticipant(.simple))
            } else {
                viewState = .loaded(.readyToBecomeParticipant(.simple))
            }

        case .accounts(let accountModelsManager):
            let (accountModel, referralInfo) = await fetchInitialData(with: accountModelsManager)
            referralProgramInfo = referralInfo
            self.accountModel = accountModel

            updateViewState(accountModel: accountModel)
            bindAccountModelsUpdates(accountModelsManager)
        }
    }

    func onAppear() {
        Analytics.log(.referralScreenOpened)
    }

    @MainActor
    func openAccountSelector() {
        guard
            let selectedCryptoAccount,
            let networkId = awardToken?.networkId
        else {
            return
        }

        let filter = makeCryptoAccountModelsFilter(networkId: networkId)

        coordinator?.showAccountSelector(
            selectedAccount: selectedCryptoAccount,
            userWalletModel: userWalletModel,
            cryptoAccountModelsFilter: filter,
            onSelect: { [weak self] cryptoAccountModel in
                guard let self else { return }

                Analytics.log(.referralListChooseAccount)
                setReadyToBecomeState(for: cryptoAccountModel)
            }
        )
    }

    private func makeCryptoAccountModelsFilter(networkId: String) -> (any CryptoAccountModel) -> Bool {
        return { [supportedBlockchains] account in
            AccountBlockchainManageabilityChecker.canManageNetwork(networkId, for: account, in: supportedBlockchains)
        }
    }

    func participateInReferralProgram() {
        runTask { [weak self] in
            guard let self else { return }

            if isProcessingRequest {
                return
            }

            isProcessingRequest = true
            Analytics.log(.referralButtonParticipate)

            guard let validatedData = validateAwardData(from: referralProgramInfo) else {
                isProcessingRequest = false
                return
            }

            do {
                guard let userTokensManager else {
                    throw ReferralError.accountFetchError
                }

                let address = try await runInTask {
                    try await userTokensManager.add(.token(validatedData.storageToken, .init(validatedData.blockchain, derivationPath: nil)))
                }

                isProcessingRequest = false

                let referralProgramInfo: ReferralProgramInfo? = try await runInTask { [weak self] in
                    guard let self else { return nil }

                    return try await tangemApiService.participateInReferralProgram(using: validatedData.award.token, for: address, with: userWalletId.hexString)
                }

                self.referralProgramInfo = referralProgramInfo

                switch workMode {
                case .plainUserTokensManager:
                    viewState = .loaded(.alreadyParticipant(.simple))

                case .accounts:
                    updateViewState(accountModel: accountModel)
                }

                Analytics.log(.referralParticipateSuccessfull)
            } catch {
                if !error.toTangemSdkError().isUserCancelled {
                    let referralError = ReferralError(error)
                    let message = Localization.referralErrorFailedToParticipate(referralError.errorCode)
                    errorAlert = AlertBuilder.makeOkErrorAlert(message: message)
                    AppLogger.error(error: referralError)
                    Analytics.log(event: .referralError, params: [.errorCode: "\(referralError.errorCode)"])
                }
            }

            isProcessingRequest = false
        }
    }

    func copyPromoCode() {
        Analytics.log(.referralButtonCopyCode)
        UIPasteboard.general.string = referralProgramInfo?.referral?.promoCode

        Toast(view: SuccessToast(text: Localization.referralPromoCodeCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    func sharePromoCode() {
        Analytics.log(.referralButtonShareCode)
        let shareActivityVC = UIActivityViewController(activityItems: [shareLink], applicationActivities: nil)
        AppPresenter.shared.show(shareActivityVC)
    }

    func updateAccount(_ newAccount: any CryptoAccountModel) {
        let accountData = SelectedAccountViewData(
            id: newAccount.id,
            iconViewData: AccountModelUtils.UI.iconViewData(icon: newAccount.icon, accountName: newAccount.name),
            name: newAccount.name
        )

        viewState = viewState.updateAccountData(with: accountData)
    }

    @MainActor
    private func loadReferralInfo() async -> ReferralProgramInfo? {
        do {
            let referralProgramInfo: ReferralProgramInfo? = try await runInTask { [weak self] in
                guard let self else { return nil }

                return try await tangemApiService.loadReferralProgramInfo(
                    for: userWalletId.hexString,
                    expectedAwardsLimit: ReferralConstants.expectedAwardsFetchLimit
                )
            }
            return referralProgramInfo
        } catch {
            let referralError = ReferralError(error)
            let message = Localization.referralErrorFailedToLoadInfoWithReason(referralError.errorCode)
            AppLogger.error(error: referralError)
            errorAlert = AlertBuilder.makeOkErrorAlert(message: message, okAction: coordinator?.dismiss ?? {})
            Analytics.log(event: .referralError, params: [.errorCode: "\(referralError.errorCode)"])

            return nil
        }
    }

    private func loadAccountModel(with accountModelsManager: AccountModelsManager) async -> AccountModel? {
        do {
            return try await accountModelsManager.accountModelsPublisher.async().firstStandard()
        } catch {
            processReferralError(.accountFetchError)
            return nil
        }
    }

    // MARK: - Loading

    private func fetchInitialData(with accountModelsManager: AccountModelsManager) async -> (AccountModel?, ReferralProgramInfo?) {
        async let accountModel = loadAccountModel(with: accountModelsManager)
        async let referralInfo = loadReferralInfo()

        return await (accountModel, referralInfo)
    }

    private func bindAccountModelsUpdates(_ accountModelsManager: AccountModelsManager) {
        accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, accountModels in
                viewModel.updateViewState(accountModel: accountModels.firstStandard())
            }
            .store(in: &bag)
    }

    // MARK: - State mapping

    private func updateViewState(accountModel: AccountModel?) {
        guard let accountModel else {
            processReferralError(.accountFetchError)
            return
        }

        switch (referralProgramInfo?.referral?.address, accountModel) {
        case (.some(let address), .standard(let cryptoAccounts)):
            mapAlreadyParticipantState(address: address, cryptoAccounts: cryptoAccounts)

        case (nil, .standard(let cryptoAccounts)):
            mapReadyToBecomeState(cryptoAccounts: cryptoAccounts)
        }
    }

    // MARK: - Validation helpers

    private func validateAwardData(from referralInfo: ReferralProgramInfo?) -> ValidatedAwardData? {
        guard let award = referralInfo?.conditions.awards.first else {
            processReferralError(.awardNotLoaded)
            return nil
        }

        guard let blockchain = supportedBlockchains[award.token.networkId] else {
            processReferralError(.blockchainNotSupported)
            return nil
        }

        guard let storageToken = award.token.storageToken else {
            processReferralError(.invalidToken)
            return nil
        }

        return ValidatedAwardData(award: award, blockchain: blockchain, storageToken: storageToken)
    }

    // MARK: - Mapping helpers

    private func mapAlreadyParticipantState(address: String, cryptoAccounts: CryptoAccounts) {
        switch cryptoAccounts {
        case .single:
            viewState = .loaded(.alreadyParticipant(.simple))

        case .multiple(let accounts):
            guard let account = ReferralAccountFinder.find(forAddress: address, accounts: accounts) else {
                viewState = .loaded(.alreadyParticipant(.simple))
                return
            }

            let viewData = SelectedAccountViewData(
                id: account.id.toAnyHashable(),
                iconViewData: AccountModelUtils.UI.iconViewData(icon: account.icon, accountName: account.name),
                name: account.name
            )
            viewState = .loaded(.alreadyParticipant(.accounts(viewData)))
        }
    }

    private func mapReadyToBecomeState(cryptoAccounts: CryptoAccounts) {
        switch cryptoAccounts {
        case .single:
            viewState = .loaded(.readyToBecomeParticipant(.simple))

        case .multiple(let accounts):
            let selectedOrMainAccount =
                accounts.first { $0.id.toAnyHashable() == selectedForReferralAccount?.id } ??
                accounts.first(where: { $0.isMainAccount })

            guard let selectedOrMainAccount else {
                processReferralError(.accountFetchError)
                return
            }

            setReadyToBecomeState(for: selectedOrMainAccount)
        }
    }

    private func setReadyToBecomeState(for account: any CryptoAccountModel) {
        guard let validatedData = validateAwardData(from: referralProgramInfo) else {
            return
        }

        let viewData = makeSelectedAccountViewData(from: account)
        let tokenType = makeTokenType(for: account, validatedData: validatedData)

        viewState = .loaded(.readyToBecomeParticipant(.accounts(tokenType, viewData)))
    }

    private func makeSelectedAccountViewData(from account: any CryptoAccountModel) -> SelectedAccountViewData {
        SelectedAccountViewData(
            id: account.id.toAnyHashable(),
            iconViewData: AccountModelUtils.UI.iconViewData(icon: account.icon, accountName: account.name),
            name: account.name
        )
    }

    private func makeTokenType(
        for account: any CryptoAccountModel,
        validatedData: ValidatedAwardData
    ) -> ReadyToBecomeParticipantDisplayMode.TokenType {
        let walletModel = account
            .walletModelsManager
            .walletModels
            .first { $0.tokenItem.token == validatedData.storageToken }

        if let walletModel {
            return .tokenItem(makeExpressTokenItemViewModel(from: walletModel))
        }

        let tokenIconInfo = tokenIconInfoBuilder.build(
            for: .token(value: validatedData.storageToken),
            in: validatedData.blockchain,
            isCustom: validatedData.storageToken.isCustom
        )
        return .token(tokenIconInfo, validatedData.storageToken.name, validatedData.storageToken.symbol)
    }

    private func processReferralError(_ error: ReferralError) {
        AppLogger.error(error: Localization.referralErrorFailedToLoadInfo)
        errorAlert = AlertBuilder.makeOkErrorAlert(
            message: Localization.referralErrorFailedToLoadInfo,
            okAction: coordinator?.dismiss ?? {}
        )
        isProcessingRequest = false
        Analytics.log(event: .referralError, params: [.errorCode: "\(error.errorCode)"])
    }

    private func makeExpressTokenItemViewModel(from walletModel: any WalletModel) -> ExpressTokenItemViewModel {
        let tokenIconInfo = tokenIconInfoBuilder.build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )

        let balance = walletModel.availableBalanceProvider.formattedBalanceType.value
        let fiatBalance = walletModel.fiatAvailableBalanceProvider.formattedBalanceType.value

        return ExpressTokenItemViewModel(
            id: walletModel.id.id,
            tokenIconInfo: tokenIconInfo,
            name: walletModel.name,
            symbol: walletModel.tokenItem.currencySymbol,
            balance: balance,
            fiatBalance: fiatBalance,
            isDisable: false,
            itemDidTap: { /* no action needed */ }
        )
    }

    private var userTokensManager: UserTokensManager? {
        switch workMode {
        case .plainUserTokensManager(let userTokensManager):
            return userTokensManager
        case .accounts:
            return selectedCryptoAccount?.userTokensManager
        }
    }

    private var selectedForReferralAccount: SelectedAccountViewData? {
        switch viewState {
        case .loading:
            return nil
        case .loaded(let loadedState):
            return loadedState.accountData
        }
    }

    private var selectedCryptoAccount: (any CryptoAccountModel)? {
        findAccount(by: selectedForReferralAccount?.id)
    }

    private var award: ReferralProgramInfo.Award? {
        referralProgramInfo?.conditions.awards.first
    }

    private var awardToken: AwardToken? {
        award?.token
    }

    private var shareLink: String {
        guard let referralInfo = referralProgramInfo?.referral else {
            return ""
        }

        return Localization.referralShareLink(referralInfo.shareLink)
    }

    private func findAccount(by id: some Hashable) -> (any CryptoAccountModel)? {
        switch workMode {
        case .plainUserTokensManager:
            return nil
        case .accounts:
            return accountModel?.cryptoAccount(with: id)
        }
    }
}

extension ReferralViewModel {
    enum ReferralError: Error {
        case awardNotLoaded
        case accountFetchError
        case blockchainNotSupported
        case invalidToken
        case decodingError(DecodingError)
        case moyaError(MoyaError)
        case unknown(Error)

        init(_ error: Error) {
            switch error {
            case let moyaError as MoyaError:
                self = .moyaError(moyaError)
            case let decodingError as DecodingError:
                self = .decodingError(decodingError)
            default:
                self = .unknown(error)
            }
        }
    }

    private struct ValidatedAwardData {
        let award: ReferralProgramInfo.Award
        let blockchain: Blockchain
        let storageToken: Token
    }
}

// MARK: UI stuff

extension ReferralViewModel {
    func awardDescription(highlightColor: Color) -> NSAttributedString {
        var formattedAward = ""
        var addressContent = ""
        var tokenName = ""

        if let award {
            formattedAward = "\(award.amount) \(award.token.symbol)"
        }

        if let address = referralProgramInfo?.referral?.address {
            let addressFormatter = AddressFormatter(address: address)
            addressContent = addressFormatter.truncated()
        }

        if let awardToken, let blockchain = supportedBlockchains[awardToken.networkId] {
            tokenName = blockchain.displayName
        }

        let rawText = Localization.referralPointCurrenciesDescription(formattedAward, tokenName, addressContent)
        return TangemRichTextFormatter(highlightColor: UIColor(highlightColor)).format(rawText)
    }

    var discount: String {
        guard let info = referralProgramInfo else {
            return ""
        }

        return Localization.referralPointDiscountDescriptionValue("\(info.conditions.discount.amount)\(info.conditions.discount.type.symbol)")
    }

    var hasPurchases: Bool {
        let count = referralProgramInfo?.referral?.walletsPurchased ?? 0
        return count > 0
    }

    var numberOfWalletsBought: String {
        let count = referralProgramInfo?.referral?.walletsPurchased ?? 0
        return Localization.referralWalletsPurchasedCount(count)
    }

    var isExpectingAwards: Bool {
        referralProgramInfo?.expectedAwards != nil
    }

    var hasExpectedAwards: Bool {
        let count = referralProgramInfo?.expectedAwards?.numberOfWallets ?? 0
        return count > 0
    }

    var numberOfWalletsForPayments: String {
        let count = referralProgramInfo?.expectedAwards?.numberOfWallets ?? 0
        return Localization.referralNumberOfWallets(count)
    }

    var expectedAwards: [ExpectedAward] {
        guard let list = referralProgramInfo?.expectedAwards?.list else {
            return []
        }

        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyy-MM-dd"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true

        let awards: [ExpectedAward] = list.map {
            let amount = "\($0.amount) \($0.currency)"

            guard
                let date = dateParser.date(from: $0.paymentDate)
            else {
                return ExpectedAward(date: $0.paymentDate, amount: amount)
            }

            let formattedDate = dateFormatter.string(from: date)
            return ExpectedAward(date: formattedDate, amount: amount)
        }

        let awardsToShow = expectedAwardsExpanded
            ? ReferralConstants.expectedAwardsFetchLimit
            : ReferralConstants.expectedAwardsShortListLimit
        return Array(awards.prefix(awardsToShow))
    }

    var canExpandExpectedAwards: Bool {
        let list = referralProgramInfo?.expectedAwards?.list ?? []
        return list.count > ReferralConstants.expectedAwardsShortListLimit
    }

    var expandButtonText: String {
        expectedAwardsExpanded ? Localization.referralLess : Localization.referralMore
    }

    var promoCode: String {
        guard let info = referralProgramInfo?.referral else {
            return ""
        }

        return info.promoCode
    }

    var tosButtonPrefix: String {
        if referralProgramInfo?.referral == nil {
            return Localization.referralTosNotEnroledPrefix + " "
        }

        return Localization.referralTosEnroledPrefix + " "
    }

    var isProgramInfoLoaded: Bool { referralProgramInfo != nil }
    var isAlreadyReferral: Bool { referralProgramInfo?.referral != nil }
}

// MARK: - Navigation

extension ReferralViewModel {
    func openTOS() {
        guard
            let link = referralProgramInfo?.conditions.tosLink,
            let url = URL(string: link)
        else {
            AppLogger.error(error: "Failed to create link")
            return
        }

        Analytics.log(.referralButtonOpenTos)
        coordinator?.openTOS(with: url)
    }
}

extension ReferralViewModel {
    struct ExpectedAward {
        let date: String
        let amount: String
    }
}

private struct TangemRichTextFormatter {
    /// Formatting rich text as NSAttributedString
    /// Supported formats: ^^color^^ for the highlight color
    private let highlightColor: UIColor

    init(highlightColor: UIColor) {
        self.highlightColor = highlightColor
    }

    func format(_ string: String) -> NSAttributedString {
        var attributedString = NSMutableAttributedString(string: string)

        attributedString = formatColor(string, attributedString, highlightColor: highlightColor)

        return attributedString
    }

    private func formatColor(_ string: String, _ attributedString: NSMutableAttributedString, highlightColor: UIColor) -> NSMutableAttributedString {
        var originalString = string

        let regex = try! NSRegularExpression(pattern: "\\^{2}.+?\\^{2}")

        let wholeRange = NSRange(location: 0, length: (originalString as NSString).length)
        let matches = regex.matches(in: originalString, range: wholeRange)

        for match in matches.reversed() {
            let formatterTagLength = 2

            let richText = String(originalString[Range(match.range, in: originalString)!])
            let plainText = richText.dropFirst(formatterTagLength).dropLast(formatterTagLength)

            originalString = originalString.replacingOccurrences(of: richText, with: plainText)

            let richTextRange = NSRange(location: match.range.location, length: match.range.length)

            attributedString.replaceCharacters(in: richTextRange, with: String(plainText))

            let plainTextRange = NSRange(location: match.range.location, length: plainText.count)
            attributedString.addAttribute(.foregroundColor, value: highlightColor, range: plainTextRange)
        }

        return attributedString
    }
}
