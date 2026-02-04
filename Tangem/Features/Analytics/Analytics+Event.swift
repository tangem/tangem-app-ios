//
//  Analytics+Event.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum Event: String {
        case signedIn = "[Basic] Signed in"
        case toppedUp = "[Basic] Topped up"
        case balanceLoaded = "[Basic] Balance Loaded"
        case tokenBalanceLoaded = "[Basic] Token Balance"
        case cardWasScanned = "[Basic] Card Was Scanned"
        case transactionSent = "[Basic] Transaction sent"
        case requestSupport = "[Basic] Request Support"
        case biometryFailed = "[Basic] Biometry Failed"
        case basicButtonBuy = "[Basic] Button - Buy"

        case buttonTokensList = "[Introduction Process] Button - Tokens List"
        case buttonBuyCards = "[Introduction Process] Button - Buy Cards"
        case introductionProcessButtonScanCard = "[Introduction Process] Button - Scan Card"
        case introductionProcessCreateWalletIntroScreenOpened = "[Introduction Process] Create Wallet Intro Screen Opened"
        case introductionProcessButtonCreateNewWallet = "[Introduction Process] Button - Create New Wallet"
        case introductionProcessButtonAddExistingWallet = "[Introduction Process] Button - Add Existing Wallet"
        case introductionProcessOpened = "[Introduction Process] Introduction Process Screen Opened"
        case introductionProcessLearn = "[Introduction Process] Button - Learn"

        case promoBuy = "[Promo Screen] Button - Buy"
        case promoSuccessOpened = "[Promo Screen] Success Screen Opened"

        case shopScreenOpened = "[Shop] Shop Screen Opened"
        case purchased = "[Shop] Purchased"
        case redirected = "[Shop] Redirected"

        case signInScreenOpened = "[Sign In] Sign In Screen Opened"
        case signInButtonWallet = "[Sign In] Button - Wallet"
        case buttonBiometricSignIn = "[Sign In] Button - Biometric Sign In"
        case buttonCardSignIn = "[Sign In] Button - Card Sign In"
        case signInErrorBiometricUpdated = "[Sign In] Error - Biometric Updated"
        case signInButtonUnlockAllWithBiometrics = "[Sign In] Button - Unlock All With Biometric"
        case buttonAddWallet = "[Sign In] Button - Add Wallet"

        case onboardingStarted = "[Onboarding] Onboarding Started"
        case onboardingFinished = "[Onboarding] Onboarding Finished"
        case onboardingCreateMobileScreenOpened = "[Onboarding / Create Wallet] Create Mobile Screen Opened"
        case createWalletScreenOpened = "[Onboarding / Create Wallet] Create Wallet Screen Opened"
        case buttonCreateWallet = "[Onboarding / Create Wallet] Button - Create Wallet"
        case buttonMobileWallet = "[Onboarding] Button - Mobile Wallet"
        case onboardingButtonBuy = "[Onboarding] Button - Buy"

        case walletCreatedSuccessfully = "[Onboarding / Create Wallet] Wallet Created Successfully"

        case backupScreenOpened = "[Onboarding / Backup] Backup Screen Opened"
        case backupStarted = "[Onboarding / Backup] Backup Started"
        case backupSkipped = "[Onboarding / Backup] Backup Skipped"
        case backupNoticeCanceled = "[Onboarding / Backup] Notice - Backup Canceled"
        case settingAccessCodeStarted = "[Onboarding / Backup] Setting Access Code Started"
        case accessCodeEntered = "[Onboarding / Backup] Access Code Entered"
        case accessCodeReEntered = "[Onboarding / Backup] Access Code Re-entered"
        case backupFinished = "[Onboarding / Backup] Backup Finished"
        case backupResetCardNotification = "[Onboarding / Backup] Reset Card Notification"
        case backupSeedPhraseInfo = "[Onboarding / Backup] Seed Phrase Info"
        case backupSeedCheckingScreenOpened = "[Onboarding / Backup] Seed Checking Screen Opened"
        case backupAccessCodeSkipped = "[Onboarding / Backup] Access Code Skipped"

        case activationScreenOpened = "[Onboarding / Top Up] Activation Screen Opened"
        case buttonBuyCrypto = "[Onboarding / Top Up] Button - Buy Crypto"
        case onboardingButtonShowTheWalletAddress = "[Onboarding / Top Up] Button - Show the Wallet Address"
        case onboardingEnableBiometric = "[Onboarding / Biometric] Enable Biometric"
        case allowBiometricID = "[Onboarding / Biometric] Allow Face ID / Touch ID (System)"
        case twinningScreenOpened = "[Onboarding / Twins] Twinning Screen Opened"
        case twinSetupStarted = "[Onboarding / Twins] Twin Setup Started"
        case twinSetupFinished = "[Onboarding / Twins] Twin Setup Finished"
        case onboardingButtonChat = "[Onboarding] Button - Chat"

        case buttonManageTokens = "[Portfolio] Button - Manage Tokens"
        case organizeTokensScreenOpened = "[Portfolio / Organize Tokens] Organize Tokens Screen Opened"
        case organizeTokensButtonSortByBalance = "[Portfolio / Organize Tokens] Button - By Balance"
        case organizeTokensButtonGroup = "[Portfolio / Organize Tokens] Button - Group"
        case organizeTokensButtonApply = "[Portfolio / Organize Tokens] Button - Apply"
        case organizeTokensButtonCancel = "[Portfolio / Organize Tokens] Button - Cancel"

        case detailsScreenOpened = "[Details Screen] Details Screen Opened"

        case buttonRemoveToken = "[Token] Button - Remove Token"
        case buttonExplore = "[Token] Button - Explore"
        case buttonReload = "[Token] Button - Reload"
        case buttonBuy = "[Token] Button - Buy"
        case buttonSell = "[Token] Button - Sell"
        case buttonExchange = "[Token] Button - Exchange"
        case buttonSend = "[Token] Button - Send"
        case buttonReceive = "[Token] Button - Receive"
        case buttonUnderstand = "[Token] Button - Understand"
        case tokenBought = "[Token] Token Bought"
        case receiveScreenOpened = "[Token / Receive] Receive Screen Opened"
        case qrScreenOpened = "[Token / Receive] QR Screen Opened"
        case buttonCopyAddress = "[Token / Receive] Button - Copy Address"
        case buttonShareAddress = "[Token / Receive] Button - Share Address"
        case buttonENS = "[Token / Receive] Button - ENS"
        case buttonAddTokenTrustline = "[Token] Button - Token Trustline"
        case stakingClicked = "[Token] Staking Clicked"

        // MARK: - Main screen

        case mainScreenOpened = "[Main Screen] Screen opened"
        case noticeRateTheAppButtonTapped = "[Main Screen] Notice - Rate The App Button Tapped"
        case noticeFinishActivation = "[Main Screen] Notice - Finish Activation"
        case mainButtonReceive = "[Main Screen] Button - Receive"
        case mainButtonExplore = "[Main Screen] Button - Explore"
        case mainButtonUnlockAllWithBiometrics = "[Main Screen] Button - Unlock All With Biometrics"
        case buttonUnlockWithCardScan = "[Main Screen] Button - Unlock With Card Scan"
        case buttonEditWalletTapped = "[Main Screen] Button - Edit Wallet Tapped"
        case buttonDeleteWalletTapped = "[Main Screen] Button - Delete Wallet Tapped"
        case apyClicked = "[Main Screen] APY Clicked"
        case mainButtonAccountShowTokens = "[Main Screen] Button - Account Show Tokens"
        case mainButtonAccountHideTokens = "[Main Screen] Button - Account Hide Tokens"

        // MARK: - Send

        case buttonPaste = "[Token / Send] Button - Paste"
        case buttonSwapCurrency = "[Token / Send] Button - Swap Currency"
        case sendScreenOpened = "[Token / Send] Send Screen Opened"
        case sendAddressEntered = "[Token / Send] Address Entered"
        case sendButtonQRCode = "[Token / Send] Button - QR Code"
        case sendAddressScreenOpened = "[Token / Send] Address Screen Opened"
        case sendAmountScreenOpened = "[Token / Send] Amount Screen Opened"
        case sendMaxAmountTapped = "[Token / Send] Max Amount Taped"
        case sendSelectedCurrency = "[Token / Send] Selected Currency"
        case sendFeeScreenOpened = "[Token / Send] Fee Screen Opened"
        case sendFeeSummaryScreenOpened = "[Token / Send] Fee Summary Screen Opened"
        case sendFeeTokenScreenOpened = "[Token / Send] Fee Token Screen Opened"
        case sendFeeSelected = "[Token / Send] Fee Selected"
        case sendCustomFeeClicked = "[Token / Send] Custom Fee Clicked"
        case sendGasPriceInserted = "[Token / Send] Gas Price Inserted"
        case sendCustomFeeInserted = "[Token / Send] Custom Fee Inserted"
        case sendGasLimitInserted = "[Token / Send] Gas Limit Inserted"
        case sendNonceInserted = "[Token / Send] Nonce Inserted"
        case sendMaxFeeInserted = "[Token / Send] Max Fee Inserted"
        case sendPriorityFeeInserted = "[Token / Send] Priority Fee Inserted"
        case sendConfirmScreenOpened = "[Token / Send] Confirm Screen Opened"
        case sendScreenReopened = "[Token / Send] Screen Reopened"
        case sendTransactionSentScreenOpened = "[Token / Send] Transaction Sent Screen Opened"
        case sendButtonShare = "[Token / Send] Button - Share"
        case sendButtonExplore = "[Token / Send] Button - Explore"
        case sendNoticeTransactionDelaysArePossible = "[Token / Send] Notice - Transaction Delays Are Possible"
        case sendErrorTransactionRejected = "[Token / Send] Error - Transaction Rejected"
        case sendButtonClose = "[Token / Send] Button - Close"
        case sendButtonConvertToken = "[Token / Send] Button - Convert Token"
        case sendTokenSearched = "[Token / Send] Token Searched"
        case sendTokenSearchedClicked = "[Token / Send] Token Search Clicked"
        case sendTokenChosen = "[Token / Send] Token chosen"
        case sendProviderClicked = "[Token / Send] Provider Clicked"
        case sendProviderChosen = "[Token / Send] Provider Chosen"
        case sendSendWithSwapInProgressScreenOpened = "[Token / Send] Send With Swap In Progress Screen Opened"
        case sendNoticeCantSwapThisToken = "[Token / Send] Notice - Can't Swap This Token"
        case sendNoticeNotEnoughFee = "[Token / Send] Notice - Not Enough Fee"
        case sendNoticeNetworkFeeCoverage = "[Token / Send] Notice - Network Fee Coverage"

        case topupScreenOpened = "[Token / Topup] Top Up Screen Opened"
        case p2PScreenOpened = "[Token / Topup] P2P Screen Opened"
        case withdrawScreenOpened = "[Token / Withdraw] Withdraw Screen Opened"
        case settingsButtonChat = "[Settings] Button - Chat"
        case settingsButtonManageTokens = "[Settings] Button - Manage Tokens"
        case settingsColdWalletAdded = "[Settings] Cold Wallet Added"
        case buttonWalletConnect = "[Settings] Button - Wallet Connect"
        case buttonStartWalletConnectSession = "[Settings] Button - Start Wallet Connect Session"
        case buttonStopWalletConnectSession = "[Settings] Button - Stop Wallet Connect Session"
        case buttonCardSettings = "[Settings] Button - Card Settings"
        case buttonAppSettings = "[Settings] Button - App Settings"
        case buttonCreateBackup = "[Settings] Button - Create Backup"
        case buttonSocialNetwork = "[Settings] Button - Social Network"
        case buttonScanNewCardSettings = "[Settings] Button - Scan New Card"
        case buttonFactoryReset = "[Settings / Card Settings] Button - Factory Reset"
        case factoryResetFinished = "[Settings / Card Settings] Factory Reset Finished"
        case factoryResetCancelled = "[Settings / Card Settings] Factory Reset Cancelled"
        case buttonChangeUserCode = "[Settings / Card Settings] Button - Change User Code"
        case userCodeChanged = "[Settings / Card Settings] User Code Changed"
        case buttonChangeSecurityMode = "[Settings / Card Settings] Button - Change Security Mode"
        case securityModeChanged = "[Settings / Card Settings] Security Mode Changed"
        case saveUserWalletSwitcherChanged = "[Settings / App Settings] Save Wallet Switcher Changed"
        case saveAccessCodeSwitcherChanged = "[Settings / App Settings] Save Access Code Switcher Changed"
        case hideBalanceChanged = "[Settings / App Settings] Hide Balance Changed"
        case settingsNoticeEnableBiometrics = "[Settings / App Settings] Notice - Enable Biometric"
        case buttonEnableBiometricAuthentication = "[Settings / App Settings] Button - Enable Biometric Authentication"
        case mainCurrencyChanged = "[Settings / App Settings] Main Currency Changed"
        case walletSettingsScreenOpened = "[Settings / Wallet Settings] Wallet Settings Screen Opened"
        case walletSettingsButtonBackup = "[Settings / Wallet Settings] Button - Backup"
        case walletSettingsButtonAccessCode = "[Settings / Wallet Settings] Button - Access Code"
        case walletSettingsBackupScreenOpened = "[Settings / Wallet Settings] Backup Screen Opened"
        case walletSettingsButtonManualBackup = "[Settings / Wallet Settings] Button - Manual Backup"
        case walletSettingsButtonRecoveryPhrase = "[Settings / Wallet Settings] Button - Recovery phrase"
        case walletSettingsButtonHardwareUpdate = "[Settings / Wallet Settings] Button - Hardware Update"
        case walletSettingsButtonCreateNewWallet = "[Settings / Wallet Settings] Button - Create New Wallet"
        case walletSettingsButtonUpgradeCurrent = "[Settings / Wallet Settings] Button - Upgrade Current"
        case walletSettingsButtonStartUpgrade = "[Settings / Wallet Settings] Button - Start Upgrade"
        case walletSettingsNoticeBackupFirst = "[Settings / Wallet Settings] Notice - Backup First"
        case walletSettingsHardwareBackupScreenOpened = "[Settings / Wallet Settings] Hardware Backup Screen Opened"
        case walletSettingsCreateWalletScreenOpened = "[Settings / Wallet Settings] Create Wallet Screen Opened"
        case walletSettingsRecoveryPhraseScreenInfo = "[Settings / Wallet Settings] Recovery Phrase Screen Info"
        case walletSettingsRecoveryPhraseScreen = "[Settings / Wallet Settings] Recovery Phrase Screen"
        case walletSettingsRecoveryPhraseCheck = "[Settings / Wallet Settings] Recovery Phrase Check"
        case walletSettingsBackupCompleteScreen = "[Settings / Wallet Settings] Backup Complete Screen"
        case walletSettingsCreateAccessCode = "[Settings / Wallet Settings] Access Code Screen Opened"
        case walletSettingsConfirmAccessCode = "[Settings / Wallet Settings] Re-enter Access Code Screen"
        case walletSettingsButtonAddAccount = "[Settings / Wallet Settings] Button - Add Account"
        case walletSettingsButtonOpenExistingAccount = "[Settings / Wallet Settings] Button - Open Existing Account"
        case walletSettingsButtonArchivedAccounts = "[Settings / Wallet Settings] Button - Archived Accounts"
        case walletSettingsLongtapAccountsOrder = "[Settings / Wallet Settings] Longtap - Accounts Order"
        case walletSettingsAccountCreated = "[Settings / Wallet Settings] Account Created"
        case walletSettingsAccountRecovered = "[Settings / Wallet Settings] Account Recovered"
        case walletSettingsArchivedAccountsScreenOpened = "[Settings / Wallet Settings] Archived Accounts Screen Opened"
        case walletSettingsButtonRecoverAccount = "[Settings / Wallet Settings] Button - Recover Account"
        case walletSettingsWalletUpgraded = "[Settings / Wallet Settings] Wallet Upgraded"

        // MARK: - Account Settings

        case accountSettingsScreenOpened = "[Settings / Account] Account Settings Screen Opened"
        case accountSettingsButtonManageTokens = "[Settings / Account] Button - Manage Tokens"
        case accountSettingsButtonArchiveAccount = "[Settings / Account] Button - Archive Account"
        case accountSettingsButtonArchiveAccountConfirmation = "[Settings / Account] Button - Archive Account Confirmation"
        case accountSettingsButtonCancelAccountArchivation = "[Settings / Account] Button - Cancel Account Archivation"
        case accountSettingsAccountArchived = "[Settings / Account] Account Archived"
        case accountSettingsButtonEdit = "[Settings / Account] Button - Edit"
        case accountSettingsEditScreenOpened = "[Settings / Account] Account Edit Screen Opened"
        case accountSettingsButtonSave = "[Settings / Account] Button - Save"
        case accountSettingsButtonAddNewAccount = "[Settings / Account] Button - Add New Account"
        case accountSettingsAccountError = "[Settings / Account] Account Error"
        case manageTokensCustomTokenAddedToAnotherAccount = "[Settings / Account] Button - Add Token To Another Account"

        // MARK: - Wallet Connect

        case walletConnectScreenOpened = "[Wallet Connect] WC Screen Opened"
        case walletConnectDisconnectAllButtonTapped = "[Wallet Connect] Button - Disconnect All"

        case walletConnectDAppDetailsDisconnectButtonTapped = "[Wallet Connect] Button - Disconnect"

        case walletConnectSessionInitiated = "[Wallet Connect] Session Initiated"
        case walletConnectSessionFailed = "[Wallet Connect] Session Failed"

        case walletConnectDAppSessionProposalReceived = "[Wallet Connect] DApp Connection Requested"
        case walletConnectDAppConnectionRequestConnectButtonTapped = "[Wallet Connect] Button - Connect"
        case walletConnectCancelButtonTapped = "[Wallet Connect] Button - Cancel"

        case walletConnectDAppConnected = "[Wallet Connect] DApp Connected"
        case walletConnectDAppConnectionFailed = "[Wallet Connect] DApp Connection Failed"
        case walletConnectDAppDisconnected = "[Wallet Connect] DApp Disconnected"

        case walletConnectSignatureRequestReceived = "[Wallet Connect] Signature Request Received"
        case walletConnectSignatureRequestReceivedFailure = "[Wallet Connect] Signature Request Received with Failed"

        case walletConnectSignatureRequestHandled = "[Wallet Connect] Signature Request Handled"
        case walletConnectSignatureRequestFailed = "[Wallet Connect] Signature Request Failed"
        case walletConnectTransactionDetailsOpened = "[Wallet Connect] Transaction Details Opened"
        case walletConnectTransactionSignButtonTapped = "[Wallet Connect] Button - Sign"

        case walletConnectTransactionSolanaLarge = "[Wallet Connect] Solana Large Transaction"
        case walletConnectTransactionSolanaLargeStatus = "[Wallet Connect] Solana Large Transaction Status"

        case chatScreenOpened = "[Chat] Chat Screen Opened"
        case settingsScreenOpened = "[Settings] Settings Screen Opened"

        // MARK: - Referral program

        case referralScreenOpened = "[Referral Program] Referral Screen Opened"
        case referralButtonParticipate = "[Referral Program] Button - Participate"
        case referralButtonCopyCode = "[Referral Program] Button - Copy"
        case referralButtonShareCode = "[Referral Program] Button - Share"
        case referralButtonOpenTos = "[Referral Program] Link - TaC"
        case referralParticipateSuccessful = "[Referral Program] Participate Successfull"
        case referralError = "[Referral Program] Referral Error"
        case referralListChooseAccount = "[Referral program / Account] List - Choose Account"

        // MARK: - Swap

        case swapScreenOpenedSwap = "[Swap] Swap Screen Opened"
        case swapSendTokenBalanceClicked = "[Swap] Send Token Balance Clicked"
        case swapChooseTokenScreenOpened = "[Swap] Choose Token Screen Opened"
        case swapChooseTokenScreenResult = "[Swap] Choose Token Screen Result"
        case swapSearchedTokenClicked = "[Swap] Searched Token Clicked"
        case swapButtonSwap = "[Swap] Button - Swap"
        case swapButtonGivePermission = "[Swap] Button - Give permission"
        case swapButtonPermissionApprove = "[Swap] Button - Permission Approve"
        case swapButtonPermissionCancel = "[Swap] Button - Permission Cancel"
        case swapButtonPermitAndSwap = "[Swap] Button - Permit and Swap"
        case swapButtonSwipe = "[Swap] Button - Swipe"
        case swapButtonPermissionLearnMore = "[Swap] Button - Permission Learn More"
        case swapSwapInProgressScreenOpened = "[Swap] Swap in Progress Screen Opened"

        case swapProviderClicked = "[Swap] Provider Clicked"
        case swapProviderChosen = "[Swap] Provider Chosen"
        case swapButtonStatus = "[Swap] Button - Status"
        case swapButtonExplore = "[Swap] Button - Explore"
        case swapNoticeNoAvailableTokensToSwap = "[Swap] Notice - No Available Tokens To Swap"
        case swapNoticeExchangeRateHasExpired = "[Swap] Notice - Exchange Rate Has Expired"
        case swapNoticeNotEnoughFee = "[Swap] Notice - Not Enough Fee"
        case swapNoticeExpressError = "[Swap] Notice - Express Error"
        case swapNoticePermissionNeeded = "[Swap] Notice - Permission Needed"

        case swapFeeScreenOpened = "[Swap] Fee Screen Opened"
        case swapFeeSummaryScreenOpened = "[Swap] Fee Summary Screen Opened"
        case swapFeeTokenScreenOpened = "[Swap] Fee Token Screen Opened"
        case swapFeeSelected = "[Swap] Fee Selected"

        // MARK: - Seed phrase

        case onboardingSeedButtonOtherCreateWalletOptions = "[Onboarding / Create Wallet] Button - Other Options"
        case onboardingSeedButtonGenerateSeedPhrase = "[Onboarding / Seed Phrase] Button - Generate Seed Phrase"
        case onboardingSeedButtonImportWallet = "[Onboarding / Seed Phrase] Button - Import Wallet"
        case onboardingSeedButtonReadMore = "[Onboarding / Seed Phrase] Button - Read More"
        case onboardingSeedButtonImport = "[Onboarding / Seed Phrase] Button - Import"

        case onboardingSeedIntroScreenOpened = "[Onboarding / Seed Phrase] Seed Intro Screen Opened"
        case onboardingSeedGenerationScreenOpened = "[Onboarding / Seed Phrase] Seed Generation Screen Opened"
        case onboardingSeedCheckingScreenOpened = "[Onboarding / Seed Phrase] Seed Checking Screen Opened"
        case onboardingSeedImportScreenOpened = "[Onboarding / Seed Phrase] Import Seed Phrase Screen Opened"

        case onboardingSeedScreenCapture = "[Onboarding / Seed Phrase] Screen Capture"

        // MARK: Express

        case tokenSwapStatus = "[Token] Swap Status"
        case tokenSwapStatusScreenOpened = "[Token] Swap Status Opened"
        case tokenButtonGoToProvider = "[Token] Button - Go To Provider"
        case tokenButtonGoToToken = "[Token] Button - Go to Token"

        // MARK: - App settings

        case appSettingsAppThemeSwitched = "[Settings / App Settings] App Theme Swithed"

        // MARK: - Card settings

        case cardSettingsButtonAccessCodeRecovery = "[Settings / Card Settings] Button - Access Code Recovery"
        case cardSettingsAccessCodeRecoveryChanged = "[Settings / Card Settings] Access Code Recovery Changed"

        // MARK: - Notifications

        case mainNoticeBackupWalletTapped = "[Main Screen] Notice - Backup Your Wallet Tapped"
        case mainNoticeScanYourCardTapped = "[Main Screen] Notice - Scan Your Card Tapped"
        case mainNoticeNetworksUnreachable = "[Main Screen] Notice - Networks  Unreachable"
        case mainNoticeCardSignedTransactions = "[Main Screen] Notice - Card Signed Transactions"
        case mainNoticeProductSampleCard = "[Main Screen] Notice - Product Sample Card"
        case mainNoticeTestnetCard = "[Main Screen] Notice - Testnet Card"
        case mainNoticeDemoCard = "[Main Screen] Notice - Demo Card"
        case mainNoticeOldCard = "[Main Screen] Notice - Old Card"
        case mainNoticeDevelopmentCard = "[Main Screen] Notice - Development Card"
        case mainNoticeMissingAddress = "[Main Screen] Notice - Missing Addresses"
        case mainNoticeWalletUnlock = "[Main Screen] Notice - Wallet Unlock"
        case mainNoticeWalletUnlockTapped = "[Main Screen] Notice - Wallet Unlock Tapped"
        case mainNoticeBackupYourWallet = "[Main Screen] Notice - Backup Your Wallet"
        case mainNoticeRateTheApp = "[Main Screen] Notice - Rate The App"
        case mainNoticeBackupErrors = "[Main Screen] Notice - Backup Errors"
        case tokenNoticeNetworkUnreachable = "[Token] Notice - Network Unreachable"
        case tokenNoticeNotEnoughFee = "[Token] Notice - Not Enough Fee"
        case tokenActionButtonDisabled = "[Token] Action Button Disabled"
        case tokenNoticeRevealTransaction = "[Token] Notice - Reveal Transaction"
        case tokenNoticeLongTimeTransaction = "[Token] Notice - Long Time Transaction"
        case tokenButtonRevealCancel = "[Token] Button - Reveal Cancel"
        case tokenButtonRevealTryAgain = "[Token] Button - Reveal Try Again"
        case walletPromoButtonClicked = "[Main Screen] Note Promo Button"
        case walletPromoAppear = "[Main Screen] Notice - Note Promo"
        case mainNoticeSeedSupport = "[Main Screen] Notice - Seed Phrase Support"
        case mainNoticeSeedSupportButtonYes = "[Main Screen] Button - Support Yes"
        case mainNoticeSeedSupportButtonNo = "[Main Screen] Button - Support No"
        case mainNoticeSeedSupport2 = "[Main Screen] Notice - Seed Phrase Support2"
        case mainNoticeSeedSupportButtonUsed = "[Main Screen] Button - Support Used"
        case mainNoticeSeedSupportButtonDeclined = "[Main Screen] Button - Support Declined"
        case mainButtonFinalizeActivation = "[Main Screen] Button - Finalize Activation"

        // MARK: - BlockchainSdk exceptions

        case blockchainSdkException = "[BlockchainSdk] Exception"

        // MARK: - Health check

        case healthCheckPolkadotAccountReset = "[Token] Polkadot Account Reset"
        case healthCheckPolkadotImmortalTransactions = "[Token] Polkadot Immortal Transactions"

        // MARK: - Promotion

        case promotionBannerAppeared = "[Promotion] Notice - Promotion Banner"
        case promotionBannerClicked = "[Promotion] Promo Banner Clicked"

        case bitcoinPromoDeeplinkActivation = "[Promotion] Bitcoin Promo Deep Link Activation"
        case bitcoinPromoActivation = "[Promotion] Bitcoin Promo Activation"

        case promotionVisaWaitlist = "[Promotion] Visa Waitlist"
        case promotionButtonJoinNow = "[Promotion] Button - Join Now"
        case promotionButtonClose = "[Promotion] Button - Close"

        // MARK: - Errors

        case cantScanTheCard = "[Errors] Cant Scan The Card"
        case cantScanTheCardButtonBlog = "[Errors] Cant Scan The Card - Button Blog"
        case cantScanTheCardTryAgainButton = "[Errors] Cant Scan The Card - Try Again Button"
        case scanErrors = "[Error] Scan Errors"
        case cardHealth = "[Error] Card Health Info"

        // MARK: - Promo

        case promoChangellyActivity = "[Promo] Changelly Activity"
        case promoPushBanner = "[Promo] Push Banner"
        case promoButtonAllowPush = "[Promo] Button - Allow Push"
        case promoButtonLaterPush = "[Promo] Button - Later Push"

        // MARK: - Push notifications

        case pushButtonAllow = "[Push] Button - Allow"
        case pushButtonPostpone = "[Push] Button - Later"
        case pushPermissionStatus = "[Push] Permission Status"
        case pushNotificationOpened = "[Push] Push Notification Opened"
        case pushNotificationScreenOpened = "[Push] Push Notification Screen Opened"
        case pushToggleClicked = "[Push] Push Toggle Clicked"

        // MARK: - Staking

        case stakingInfoScreenOpened = "[Staking] Staking Info Screen Opened"
        case stakingLinkWhatIsStaking = "[Staking] Link - What Is Staking"
        case stakingButtonStake = "[Staking] Button - Stake"
        case stakingAmountScreenOpened = "[Staking] Amount Screen Opened"
        case stakingScreenReopened = "[Staking] Screen Reopened"
        case stakingButtonMax = "[Staking] Button - Max"
        case stakingButtonNext = "[Staking] Button - Next"
        case stakingButtonCancel = "[Staking] Button - Cancel"
        case stakingButtonValidator = "[Staking] Button - Validator"
        case stakingValidatorChosen = "[Staking] Validator Chosen"
        case stakingStakeInProgressScreenOpened = "[Staking] Stake In Progress Screen Opened"
        case stakingButtonRewards = "[Staking] Button - Rewards"
        case stakingRewardScreenOpened = "[Staking] Reward Screen Opened"
        case stakingButtonClaim = "[Staking] Button - Claim"
        case stakingButtonRestake = "[Staking] Button - Restake"
        case stakingButtonUnstake = "[Staking] Button - Unstake"
        case stakingButtonWithdraw = "[Staking] Button - Withdraw"
        case stakingConfirmationScreenOpened = "[Staking] Confirmation Screen Opened"
        case stakingErrors = "[Staking] Errors"
        case stakingErrorTransactionRejected = "[Staking] Error - Transaction Rejected"
        case stakingAppErrors = "[Staking] App Errors"
        case stakingSelectedCurrency = "[Staking] Selected Currency"
        case stakingButtonShare = "[Staking] Button - Share"
        case stakingButtonExplore = "[Staking] Button - Explore"
        case stakingNoticeUninitializedAddress = "[Staking] Notice - Uninitialized Address"
        case stakingUninitializedAddressScreen = "[Staking] Uninitialized Address Screen"
        case stakingNoticeNotEnoughFee = "[Staking] Notice - Not Enough Fee"
        case stakingButtonActivate = "[Staking] Button - Activate"

        // MARK: - Markets

        case marketsScreenOpened = "[Markets] Markets Screen Opened"
        case marketsTokenListOpened = "[Markets] Token List Opened"
        case marketsNewsListOpened = "[Markets] News List Opened"
        case marketsTokensSort = "[Markets] Sort By"
        case marketsDataError = "[Markets] Data Error"
        case marketsMarketsLoadError = "[Markets] Markets Load Error"
        case marketsNewsLoadError = "[Markets] News Load Error"
        case marketsAllWidgetsLoadError = "[Markets] All Widgets Load Error"
        case marketsNewsCarouselScrolled = "[Markets] News Carousel Scrolled"
        case marketsNewsCarouselEndReached = "[Markets] News Carousel End Reached"
        case marketsNewsCarouselAllNewsButton = "[Markets] News Carousel All News button"
        case marketsNewsCarouselTrendingClicked = "[Markets] News Carousel Trending Clicked"
        case marketsNewsListLoadError = "[Markets] News List Load Error"
        case marketsNewsCategoriesSelected = "[Markets] News Categories Selected"
        case marketsNoticeYieldModePromo = "[Markets] Notice - Yield Mode Promo"
        case marketsYieldModePromoClosed = "[Markets] Yield Mode Promo Closed"
        case marketsYieldModeMoreInfo = "[Markets] Yield Mode More Info"
        case marketsTokenSearch = "[Markets] Token Search"
        case marketsTokenSearchedClicked = "[Markets] Token Searched Clicked"

        // MARK: - Markets / Chart

        case marketsChartScreenOpened = "[Markets / Chart] Token Chart Screen Opened"
        case marketsChartShowedTokensBelowCapThreshold = "[Markets / Chart] Button - Show Tokens"
        case marketsChartButtonPeriod = "[Markets / Chart] Button - Period"
        case marketsChartButtonReadMore = "[Markets / Chart] Button - Read More"
        case marketsChartButtonLinks = "[Markets / Chart] Button - Links"
        case marketsChartButtonAddToPortfolio = "[Markets / Chart] Button - Add To Portfolio"
        case marketsChartWalletSelected = "[Markets / Chart] Wallet Selected"
        case marketsChartTokenNetworkSelected = "[Markets / Chart] Token Network Selected"
        case marketsChartButtonBuy = "[Markets / Chart] Button - Buy"
        case marketsChartButtonReceive = "[Markets / Chart] Button - Receive"
        case marketsChartButtonSwap = "[Markets / Chart] Button - Swap"
        case marketsChartButtonStake = "[Markets / Chart] Button - Stake"
        case marketsChartButtonYieldMode = "[Markets/Charts] Button - Yield Mode"
        case marketsChartDataError = "[Markets / Chart] Data Error"
        case marketsChartExchangesScreenOpened = "[Markets / Chart] Exchanges Screen Opened"
        case marketsChartSecurityScoreInfo = "[Markets / Chart] Security Score Info"
        case marketsChartSecurityScoreProviderClicked = "[Markets / Chart] Security Score Provider Clicked"
        case marketsChartPopupChooseAccount = "[Markets / Chart] - Choose Account Opened"
        case marketsChartButtonAddTokenToAnotherAccount = "[Markets / Chart] Button - Add To Account"
        case marketsChartPopupGetTokenButtonBuy = "[Markets / Chart] Popup Get token - Button Buy"
        case marketsChartPopupGetTokenButtonExchange = "[Markets / Chart] Popup Get token - Button Exchange"
        case marketsChartPopupGetTokenButtonReceive = "[Markets / Chart] Popup Get token - Button Receive"
        case marketsChartPopupGetTokenButtonLater = "[Markets / Chart] Popup Get token - Button Later"

        // MARK: - Manage Tokens

        case manageTokensScreenOpened = "[Manage Tokens] Manage Tokens Screen Opened"
        case manageTokensTokenIsNotFound = "[Manage Tokens] Token Is Not Found"
        case manageTokensSwitcherChanged = "[Manage Tokens] Token Switcher Changed"
        case manageTokensButtonLater = "[Manage Tokens] Button - Later"
        case manageTokensTokenAdded = "[Manage Tokens] Token Added"

        case manageTokensSearched = "[Manage Tokens] Token Searched"
        case manageTokensWalletSelected = "[Manage Tokens] Wallet Selected"

        // MARK: - Manage Tokens / Custom

        case manageTokensButtonCustomToken = "[Manage Tokens / Custom] Button - Custom Token"
        case manageTokensCustomTokenScreenOpened = "[Manage Tokens / Custom] Custom Token Screen Opened"
        case manageTokensCustomTokenWasAdded = "[Manage Tokens / Custom] Custom Token Was Added"
        case manageTokensCustomTokenNetworkSelected = "[Manage Tokens / Custom] Custom Token Network Selected"
        case manageTokensCustomTokenDerivationSelected = "[Manage Tokens / Custom] Custom Token Derivation Selected"
        case manageTokensCustomTokenAddress = "[Manage Tokens / Custom] Custom Token Address"
        case manageTokensCustomTokenName = "[Manage Tokens / Custom] Custom Token Name"
        case manageTokensCustomTokenSymbol = "[Manage Tokens / Custom] Custom Token Symbol"
        case manageTokensCustomTokenDecimals = "[Manage Tokens / Custom] Custom Token Decimals"

        // MARK: - Onramp

        case onrampBuyScreenOpened = "[Onramp] Buy Screen Opened"
        case onrampCurrencyScreenOpened = "[Onramp] Currency Screen Opened"
        case onrampCurrencyChosen = "[Onramp] Currency Chosen"
        case onrampButtonClose = "[Onramp] Button - Close"
        case onrampOnrampSettingsScreenOpened = "[Onramp] Onramp Settings Screen Opened"
        case onrampResidenceScreenOpened = "[Onramp] Residence Screen Opened"
        case onrampResidenceChosen = "[Onramp] Residence Chosen"
        case onrampResidenceConfirmScreen = "[Onramp] Residence Confirm Screen"
        case onrampButtonChange = "[Onramp] Button - Change"
        case onrampButtonConfirm = "[Onramp] Button - Confirm"
        case onrampProvidersScreenOpened = "[Onramp] Providers Screen Opened"
        case onrampProviderCalculated = "[Onramp] Provider Calculated"
        case onrampPaymentMethodScreenOpened = "[Onramp] Payment Method Screen Opened"
        case onrampMethodChosen = "[Onramp] Method Chosen"
        case onrampProviderChosen = "[Onramp] Provider Chosen"
        case onrampButtonBuy = "[Onramp] Button - Buy"
        case onrampErrorMinAmount = "[Onramp] Error - Min Amount"
        case onrampErrorMaxAmount = "[Onramp] Error - Max Amount"
        case onrampErrors = "[Onramp] Errors"
        case onrampAppErrors = "[Onramp] App Errors"
        case onrampBuyingInProgressScreenOpened = "[Onramp] Buying In Progress Screen Opened"
        case onrampNoticeKYC = "[Onramp] Notice - KYC"
        case onrampOnrampStatusOpened = "[Onramp] Onramp Status Opened"
        case onrampButtonGoToProvider = "[Onramp] Button - Go To Provider"
        case onrampOnrampStatus = "[Onramp] Onramp Status"
        case onrampRecentlyUsedClicked = "[Onramp] Recently Used Clicked"
        case onrampFastestMethodClicked = "[Onramp] Fastest Method Clicked"
        case onrampBestRateClicked = "[Onramp] Best Rate Clicked"
        case onrampButtonAllOffers = "[Onramp] Button - All Offers"

        // MARK: - Action Buttons

        case actionButtonsBuyButton = "[Main Screen] Button - Buy"
        case actionButtonsSellButton = "[Main Screen] Button - Sell"
        case actionButtonsSwapButton = "[Main Screen] Button - Swap"
        case actionButtonsSwapScreenOpened = "[Main Screen] Swap Screen Opened"
        case actionButtonsBuyScreenOpened = "[Main Screen] Buy Screen Opened"
        case actionButtonsSellScreenOpened = "[Main Screen] Sell Screen Opened"
        case actionButtonsSellTokenClicked = "[Main Screen] Sell Token Clicked"
        case actionButtonsBuyTokenClicked = "[Main Screen] Buy Token Clicked"
        case actionButtonsSwapTokenClicked = "[Main Screen] Swap Token Clicked"
        case actionButtonsReceiveTokenClicked = "[Main Screen] Receive Token Clicked"
        case actionButtonsRemoveButtonClicked = "[Main Screen] Remove Button Clicked"
        case actionButtonsButtonClose = "[Main Screen] Button - Close"
        case actionButtonsHotTokenClicked = "[Main Screen] Hot Token Clicked"
        case actionButtonsHotTokenError = "[Main Screen] Hot Token Error"

        // MARK: - Stories

        case storiesSwapShown = "[Stories] Swap Stories"
        case storiesError = "[Stories] Error"

        // MARK: - Tangem API Service

        case tangemAPIException = "[Tangem API Service] Exception"

        // MARK: - Visa

        // Onboarding events

        case visaOnboardingActivationScreenOpened = "[Onboarding / Visa] Activation Screen Opened"
        case visaOnboardingSetAccessCodeScreenOpened = "[Onboarding / Visa] Setting Access Code Started"
        case visaOnboardingReEnterAccessCodeScreenOpened = "[Onboarding / Visa] Access Code Re-enter Screen"
        case visaOnboardingChooseWalletScreenOpened = "[Onboarding / Visa] Choose Wallet Screen"
        case visaOnboardingTangemWalletPrepareScreenOpened = "[Onboarding / Visa] Wallet Prepare"
        case visaOnboardingDAppScreenOpened = "[Onboarding / Visa] Go To Website Opened"
        case visaOnboardingActivationInProgressScreenOpened = "[Onboarding / Visa] Activation In Progress Screen"
        case visaOnboardingPinCodeScreenOpened = "[Onboarding / Visa] PIN Code Screen Opened"
        case visaOnboardingBiometricScreenOpened = "[Onboarding / Visa] Biometric Screen Opened"
        case visaOnboardingSuccessScreenOpened = "[Onboarding / Visa] Success Screen Opened"
        case visaOnboardingButtonActivate = "[Onboarding / Visa] Button - Activate"
        case visaOnboardingButtonAccessCodeContinue = "[Onboarding / Visa] Access Code Entered"
        case visaOnboardingButtonStartActivation = "[Onboarding / Visa] Access Code Re-entered"
        case visaOnboardingButtonApprove = "[Onboarding / Visa] Button - Approve"
        case visaOnboardingButtonBrowser = "[Onboarding / Visa] Button - Browser"
        case visaOnboardingButtonShareLink = "[Onboarding / Visa] Button - Share Link"
        case visaOnboardingButtonSubmitPin = "[Onboarding / Visa] PIN Entered"

        case visaErrors = "[Visa] Errors"
        case visaOnboardingErrorPinValidation = "[Onboarding / Visa] Error - Pin Validation"

        // Main screen events

        case visaMainBalancesLimits = "[Main Screen] Limits Clicked"
        case visaMainNoticeBalancesInfo = "[Main Screen] Notice - Balances Info"
        case visaMainNoticeLimitsInfo = "[Main Screen] Notice - Limits Info"

        // Tangem Pay (Visa 2.0)

        case visaOnboardingVisaActivationScreenOpened = "[Visa Onboarding] Visa Activation Screen Opened"
        case visaOnboardingButtonVisaViewTerms = "[Visa Onboarding] Button - Visa View Terms"
        case visaOnboardingButtonVisaGetCard = "[Visa Onboarding] Button - Visa Get Card"
        case visaOnboardingVisaKYCFlowOpened = "[Visa Onboarding] Visa KYC Flow Opened"
        case visaOnboardingChooseWalletPopup = "[Visa Onboarding] Choose Wallet Popup"
        case visaOnboardingVisaIssuingBannerDisplayed = "[Visa Onboarding] Visa Issuing Banner Displayed"

        case visaScreenVisaMainScreenOpened = "[Visa Screen] Visa Main Screen Opened"
        case visaScreenCardSettingsClicked = "[Visa Screen] Button - Card Settings"
        case visaScreenTermsAndLimitsClicked = "[Visa Screen] Button - Terms And Limits"

        case visaScreenFreezeCardClicked = "[Visa Screen] Button - Freeze Card"
        case visaScreenFreezeCardConfirmShown = "[Visa Screen] Popup - Freeze Confirmation"
        case visaScreenFreezeCardConfirmClicked = "[Visa Screen] Button - Freeze Confirmation On Popup"
        case visaScreenUnfreezeCardClicked = "[Visa Screen] Button - Unfreeze Card"
        case visaScreenUnfreezeCardConfirmShown = "[Visa Screen] Popup - Unfreeze Confirmation"
        case visaScreenUnfreezeCardConfirmClicked = "[Visa Screen] Button - Unfreeze Confirmation On Popup"
        case visaScreenPinCodeClicked = "[Visa Screen] Button - PIN Code"
        case visaScreenChangePinScreenShown = "[Visa Screen] Screen - Change PIN"
        case visaScreenChangePinSubmitClicked = "[Visa Screen] Button - Set PIN On Change PIN Screen"
        case visaScreenChangePinSuccessShown = "[Visa Screen] Message - PIN Setup Success"
        case visaScreenCurrentPinShown = "[Visa Screen] Popup - Current PIN"
        case visaScreenChangePinOnCurrentPinClicked = "[Visa Screen] Button - Change PIN On Current PIN"
        case visaScreenViewCardDetailsClicked = "[Visa Screen] Button - View Card Details"
        case visaScreenCopyCardNumberClicked = "[Visa Screen] Button - Copy Card Number"
        case visaScreenCopyCardExpiryClicked = "[Visa Screen] Button - Copy Card Expiry"
        case visaScreenCopyCardCVVClicked = "[Visa Screen] Button - Copy CVV"
        case visaScreenAddToWalletClicked = "[Visa Screen] Button - Add Card To Wallet"
        case visaScreenWithdrawClicked = "[Visa Screen] Button - Visa Withdraw"
        case visaScreenGoToSupportOnBetaBannerClicked = "[Visa Screen] Button - Go To Support On Beta Banner"
        case visaScreenTransactionInListClicked = "[Visa Screen] Clicked On Transaction In List"
        case visaScreenSupportOnTransactionPopupClicked = "[Visa Screen] Button - Support On Transaction Popup"
        case visaScreenButtonVisaAddFunds = "[Visa Screen] Button - Visa Add Funds"
        case visaScreenButtonVisaReceive = "[Visa Screen] Button - Visa Receive"
        case visaScreenButtonVisaSwap = "[Visa Screen] Button - Visa Swap"

        // MARK: - NFT

        case nftAssetReadMore = "[NFT] Button - Read More"
        case nftAssetSeeAll = "[NFT] Button - See All"
        case nftAssetExplore = "[NFT] Button - Explore"
        case nftAssetSend = "[NFT] Button - Send"

        case nftAssetDetailsOpened = "[NFT] NFT Details Screen Opened"
        case nftAssetReceiveOpened = "[NFT] Receive NFT Screen Opened"
        case nftCollectionsOpened = "[NFT] NFT List Screen Opened"

        case nftReceiveBlockchainChosen = "[NFT] Blockchain Chosen"
        case nftReceiveCopyAddressButtonClicked = "[NFT] Button - Copy Address"
        case nftReceiveShareAddressButtonClicked = "[NFT] Button - Share Address"

        case nftSendAddressEntered = "[NFT] Send Address Entered"
        case nftCommissionScreenOpened = "[NFT] Commission Screen Opened"
        case nftFeeSelected = "[NFT] Fee Selected"
        case nftConfirmScreenOpened = "[NFT] Confirm Screen Opened"
        case nftSentScreenOpened = "[NFT] NFT Sent Screen Opened"

        case nftErrors = "[NFT] NFT Errors"
        case nftToggleSwitch = "[Settings / Wallet] NFT toggle switch"

        // MARK: - Yield

        case earningScreenInfoOpened = "[Earning] Earning Screen Info Opened"
        case earningStartScreen = "[Earning] Start Earning Screen"
        case earningButtonStart = "[Earning] Button - Start Earning"
        case earningStopScreen = "[Earning] Stop Earning Screen"
        case earningButtonStop = "[Earning] Button - Stop Earning"
        case earningButtonFeePolicy = "[Earning] Button - Fee Policy"
        case earningInProgressScreen = "[Earning] Earn In Progress Screen"
        case earningFundsEarned = "[Earning] Funds Earned"
        case earningFundsWithdrawed = "[Earning] Funds Withdrawn"
        case earningEarnedFundsInfo = "[Earning] Earned Funds Info"
        case earningNoticeNotEnoughFee = "[Earning] Notice - Not Enough Fee"
        case earningNoticeApproveNeeded = "[Earning] Notice - Approve Needed"
        case earningButtonGiveApprove = "[Earning] Button - Give Approve"
        case earningNoticeHighNetworkFee = "[Earning] Notice - High Network Fee"
        case earningErrors = "[Earning] Earn Errors"
        case earningNoticeAmountNotDeposited = "[Earning] Notice - Amount Not Deposited"
        case mainNoticeYieldPromo = "[Main Screen] Yield Promo"
        case mainNoticeYieldPromoClicked = "[Main Screen] Yield Promo Clicked"

        // MARK: - News

        case newsArticleOpened = "[Markets] News Article Opened"
        case newsRelatedClicked = "[Markets] Related News Clicked"
        case newsArticleLoadError = "[Markets] News Article Load Error"
        case newsLikeClicked = "[Markets] News Like Clicked"
        case newsLinkMismatch = "[Markets] News Link Mismatch"

        // MARK: - News (CoinPage)

        case coinPageTokenNewsViewed = "[CoinPage] Token News Viewed"
        case coinPageTokenNewsLoadError = "[CoinPage] Token News Load Error"
        case coinPageTokenNewsCarouselScrolled = "[CoinPage] Token News Carousel Scrolled"
    }
}
