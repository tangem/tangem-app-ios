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

    @MainActor
    @Published var isProcessingRequest: Bool = false

    @MainActor
    @Published var errorAlert: AlertBinder?

    @MainActor
    @Published var expectedAwardsExpanded = false

    @MainActor
    @Published private(set) var viewState: ViewState = .loading

    var mainButtonIcon: MainButton.Icon? {
        CommonTangemIconProvider(config: userWalletModel.config).getMainButtonIcon()
    }

    @MainActor
    private var accountModel: AccountModel?

    @MainActor
    private var referralProgramInfo: ReferralProgramInfo?

    private let userWalletId: Data
    private let supportedBlockchains: Set<Blockchain>
    private let userWalletModel: UserWalletModel
    private let workMode: WorkMode
    private let tokenIconInfoBuilder: TokenIconInfoBuilder
    private var bag = Set<AnyCancellable>()

    private weak var coordinator: ReferralRoutable?

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
        case .plainUserTokensManager(let userTokensManager):
            let referralInfo = await loadReferralInfo()
            referralProgramInfo = referralInfo

            if referralInfo?.referral != nil {
                updateViewState(to: .loaded(.alreadyParticipant(.simple(userTokensManager))))
            } else {
                updateViewState(to: .loaded(.readyToBecomeParticipant(.simple(userTokensManager))))
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

            let canProceed = await setIsProcessingRequestIfNeeded(true)
            guard canProceed else { return }

            Analytics.log(.referralButtonParticipate)

            guard let validatedData = await validateAwardData(from: referralProgramInfo) else {
                await setIsProcessingRequest(false)
                return
            }

            do {
                let userTokensManager = await userTokensManager

                guard let userTokensManager else {
                    await MainActor.run { AppLogger.error(error: "Can't fetch UserTokensManager for state '\(self.viewState)'") }
                    throw ReferralError.accountFetchError
                }

                let address = try await userTokensManager.add(
                    .token(validatedData.storageToken, .init(validatedData.blockchain, derivationPath: nil))
                )

                let referralProgramInfo = try await tangemApiService.participateInReferralProgram(
                    using: validatedData.award.token, for: address, with: userWalletId.hexString
                )

                await MainActor.run { self.referralProgramInfo = referralProgramInfo }

                switch workMode {
                case .plainUserTokensManager:
                    await updateViewState(to: .loaded(.alreadyParticipant(.simple(userTokensManager))))
                case .accounts:
                    await updateViewState(accountModel: accountModel)
                }

                Analytics.log(.referralParticipateSuccessful)
            } catch {
                if !error.toTangemSdkError().isUserCancelled {
                    let referralError = ReferralError(error)
                    let message = Localization.referralErrorFailedToParticipate(referralError.errorCode)
                    await MainActor.run { self.errorAlert = AlertBuilder.makeOkErrorAlert(message: message) }
                    AppLogger.error(error: referralError)
                    Analytics.log(event: .referralError, params: [.errorCode: "\(referralError.errorCode)"])
                }
            }

            await setIsProcessingRequest(false)
        }
    }

    @MainActor
    func copyPromoCode() {
        Analytics.log(.referralButtonCopyCode)
        UIPasteboard.general.string = referralProgramInfo?.referral?.promoCode

        Toast(view: SuccessToast(text: Localization.referralPromoCodeCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    @MainActor
    func sharePromoCode() {
        Analytics.log(.referralButtonShareCode)
        let shareActivityVC = UIActivityViewController(activityItems: [shareLink], applicationActivities: nil)
        AppPresenter.shared.show(shareActivityVC)
    }

    @MainActor
    func updateAccount(_ newAccount: any CryptoAccountModel) {
        let accountData = SelectedAccountViewData(
            id: newAccount.id,
            iconViewData: AccountModelUtils.UI.iconViewData(icon: newAccount.icon, accountName: newAccount.name),
            name: newAccount.name
        )

        updateViewState(to: viewState.updateAccountData(with: accountData))
    }

    @MainActor
    private func loadReferralInfo() async -> ReferralProgramInfo? {
        do {
            return try await tangemApiService.loadReferralProgramInfo(
                for: userWalletId.hexString,
                expectedAwardsLimit: ReferralConstants.expectedAwardsFetchLimit
            )
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
            AppLogger.error(error: "Can't load account models with error: \(error)")
            await processReferralError(.accountFetchError)
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
                // Already on the main thread due to `receiveOnMain` call above
                MainActor.assumeIsolated { viewModel.updateViewState(accountModel: accountModels.firstStandard()) }
            }
            .store(in: &bag)
    }

    // MARK: - State mapping

    @MainActor
    private func setIsProcessingRequestIfNeeded(_ isProcessing: Bool) -> Bool {
        guard !isProcessingRequest else {
            return false
        }

        setIsProcessingRequest(isProcessing)

        return true
    }

    @MainActor
    private func setIsProcessingRequest(_ isProcessing: Bool) {
        isProcessingRequest = isProcessing
    }

    @MainActor
    private func updateViewState(accountModel: AccountModel?) {
        guard let accountModel else {
            AppLogger.error(error: "Can't update view state because account model is nil")
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

    @MainActor
    private func updateViewState(to newViewState: ViewState) {
        switch newViewState {
        case .failed(let reason):
            AppLogger.error(error: "Failed to render referral content with reason: '\(reason)'")
        case .loading,
             .loaded:
            break
        }

        viewState = newViewState
    }

    // MARK: - Validation helpers

    @MainActor
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

    @MainActor
    private func mapAlreadyParticipantState(address: String, cryptoAccounts: CryptoAccounts) {
        switch cryptoAccounts {
        case .single(let cryptoAccountModel):
            updateViewState(to: .loaded(.alreadyParticipant(.simple(cryptoAccountModel.userTokensManager))))

        case .multiple(let accounts):
            guard let account = ReferralAccountFinder.find(forAddress: address, accounts: accounts) else {
                updateViewState(to: .failed(reason: "Can't find target account for address '\(address)'"))
                return
            }

            let viewData = makeSelectedAccountViewData(from: account)
            updateViewState(to: .loaded(.alreadyParticipant(.accounts(viewData))))
        }
    }

    @MainActor
    private func mapReadyToBecomeState(cryptoAccounts: CryptoAccounts) {
        switch cryptoAccounts {
        case .single(let cryptoAccountModel):
            updateViewState(to: .loaded(.readyToBecomeParticipant(.simple(cryptoAccountModel.userTokensManager))))

        case .multiple(let accounts):
            let selectedOrMainAccount =
                accounts.first { $0.id.toAnyHashable() == selectedForReferralAccount?.id } ??
                accounts.first(where: { $0.isMainAccount })

            guard let selectedOrMainAccount else {
                AppLogger.error(error: "Can't find selected or main account among accounts: \(accounts.map { $0.id })")
                processReferralError(.accountFetchError)
                return
            }

            setReadyToBecomeState(for: selectedOrMainAccount)
        }
    }

    @MainActor
    private func setReadyToBecomeState(for account: any CryptoAccountModel) {
        guard let validatedData = validateAwardData(from: referralProgramInfo) else {
            return
        }

        let viewData = makeSelectedAccountViewData(from: account)
        let tokenType = makeTokenType(for: account, validatedData: validatedData)

        updateViewState(to: .loaded(.readyToBecomeParticipant(.accounts(tokenType, viewData))))
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

    @MainActor
    private func processReferralError(_ error: ReferralError) {
        AppLogger.error(error: error)
        errorAlert = AlertBuilder.makeOkErrorAlert(
            message: Localization.referralErrorFailedToLoadInfo,
            okAction: coordinator?.dismiss ?? {}
        )
        setIsProcessingRequest(false)
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

    @MainActor
    private var userTokensManager: UserTokensManager? {
        switch (workMode, viewState) {
        case (.plainUserTokensManager(let userTokensManager), _):
            // Plain UI w/o accounts
            return userTokensManager
        case (.accounts, .loaded(.alreadyParticipant(.simple(let userTokensManager)))),
             (.accounts, .loaded(.readyToBecomeParticipant(.simple(let userTokensManager)))):
            // Plain UI with a single main account
            return userTokensManager
        case (.accounts, _):
            // Accounts-aware UI with multiple accounts
            return selectedCryptoAccount?.userTokensManager
        }
    }

    @MainActor
    private var selectedForReferralAccount: SelectedAccountViewData? {
        switch viewState {
        case .loading,
             .failed:
            return nil
        case .loaded(let loadedState):
            return loadedState.accountData
        }
    }

    @MainActor
    private var selectedCryptoAccount: (any CryptoAccountModel)? {
        findAccount(by: selectedForReferralAccount?.id)
    }

    @MainActor
    private var award: ReferralProgramInfo.Award? {
        referralProgramInfo?.conditions.awards.first
    }

    @MainActor
    private var awardToken: AwardToken? {
        award?.token
    }

    @MainActor
    private var shareLink: String {
        guard let referralInfo = referralProgramInfo?.referral else {
            return ""
        }

        return Localization.referralShareLink(referralInfo.shareLink)
    }

    @MainActor
    private func findAccount(by id: some Hashable) -> (any CryptoAccountModel)? {
        switch workMode {
        case .plainUserTokensManager:
            return nil
        case .accounts:
            return accountModel?.cryptoAccount(with: id)
        }
    }
}

// MARK: - Nested Types

extension ReferralViewModel {
    enum ReferralError: Error {
        case awardNotLoaded
        case accountFetchError
        case blockchainNotSupported
        case invalidToken
        case decodingError(DecodingError)
        case moyaError(MoyaError)
        case unknown(Error)

        fileprivate init(_ error: Error) {
            switch error {
            case let moyaError as MoyaError:
                self = .moyaError(moyaError)
            case let decodingError as DecodingError:
                self = .decodingError(decodingError)
            case let referralError as ReferralError:
                self = referralError
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

    struct ExpectedAward {
        let date: String
        let amount: String
    }
}

// MARK: - UI Helpers

@MainActor
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

        let awards: [ExpectedAward] = list.map {
            let amount = "\($0.amount) \($0.currency)"

            guard let date = DateFormatter.dateParser.date(from: $0.paymentDate) else {
                return ExpectedAward(date: $0.paymentDate, amount: amount)
            }

            let formattedDate = DateFormatter.dateFormatter.string(from: date)
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

@MainActor
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

// MARK: - Convenience extensions

private extension DateFormatter {
    static let dateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
