//
//  AddWalletSheetOption.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

enum AddWalletSheetOption: Hashable, Identifiable {
    case hardwareWallet
    case appleSignIn
    case seedPhraseWallet
    case importWallet

    var id: Self { self }

    var title: String {
        switch self {
        case .hardwareWallet: Localization.introductionCreateWalletHardwareTitle
        case .appleSignIn: Localization.introductionIHaveWalletSocialTitle(MobileBackupConstants.appleServiceName)
        case .seedPhraseWallet: Localization.introductionCreateWalletSeedPhraseTitle
        case .importWallet: Localization.hwImportExistingWallet
        }
    }

    var subtitle: String {
        switch self {
        case .hardwareWallet: Localization.introductionIHaveWalletHardwareDescription
        case .appleSignIn, .seedPhraseWallet, .importWallet: Localization.introductionCreateWalletSeedPhraseDescription
        }
    }

    var icon: ImageType {
        switch self {
        case .hardwareWallet: DesignSystem.Icons.LogoTangem.regular20
        case .appleSignIn: DesignSystem.Icons.LogoApple.regular20
        case .seedPhraseWallet: DesignSystem.Icons.WalletPlus.regular20
        case .importWallet: DesignSystem.Icons.ArrowDown.regular20
        }
    }
}
