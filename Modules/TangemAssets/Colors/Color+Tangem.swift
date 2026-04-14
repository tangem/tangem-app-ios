//
//  Color+.swift
//  TangemAssets
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Tangem colors

public extension Color {
    enum Tangem {
        public enum Text {}
        public enum Graphic {}
        public enum Status {}
        public enum Button {}
        public enum Surface {}
        public enum Controls {}
        public enum Border {}
        public enum Field {}
        public enum Overlay {}
        public enum Fill {}
        public enum Skeleton {}
        public enum Markers {}
        public enum Visa {}
        public enum Tabs {}
        public enum CardCollection {}
        public enum Market {}
    }
}

private typealias Primitives = DesignSystemColors.Primitives

// MARK: - Alphas

extension Primitives {
    static let lightAlpha: Color = Base.white
    static let darkAlpha: Color = Darks.dark6
}

// MARK: - Text

public extension Color.Tangem.Text {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
        public static let primaryInverted: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
        public static let primaryInvertedConstant: Color = Primitives.Base.white
        public static let secondary: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
        public static let tertiary: Color = Primitives.Darks.dark1
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let disabled: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
        public static let positive: Color = Primitives.Green.eucalyptus
    }
}

// MARK: - Graphic

public extension Color.Tangem.Graphic {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
        public static let primaryInverted: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
        public static let primaryInvertedConstant: Color = Primitives.Base.white
        public static let secondary: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
        public static let tertiary: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
        public static let tertiaryConstant: Color = Primitives.Darks.dark1
        public static let quaternary: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
        public static let positive: Color = Primitives.Green.eucalyptus
    }
}

// MARK: - Button

public extension Color.Tangem.Button {
    static let backgroundPrimary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light1)
    static let backgroundSecondary: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.1), dark: Primitives.lightAlpha.opacity(0.1))
    static let backgroundDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let backgroundPrimaryInverted: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.lightAlpha.opacity(0.1))
    static let backgroundAccent: Color = Primitives.Blue.azure
    static let backgroundPositive: Color = Primitives.Green.eucalyptus
    static let textPrimary: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let textSecondary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light4)
    static let textDisabled: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Lights.light5)
    static let iconPrimary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light4)
    static let iconSecondary: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let iconDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let borderPrimary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light4)
}

// MARK: - Surface

public extension Color.Tangem.Surface {
    static let level1: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Base.black)
    static let level2: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark7)
    static let level3: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
    static let level4: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark5)
}

// MARK: - Controls

public extension Color.Tangem.Controls {
    static let backgroundChecked: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Blue.azure)
    static let backgroundDefault: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let iconDefault: Color = Primitives.Base.white
    static let iconDisabled: Color = Primitives.Base.white
}

// MARK: - Border

public extension Color.Tangem.Border {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
        public static let secondary: Color = .dynamic(light: Primitives.Lights.light5, dark: Primitives.Darks.dark4)
        public static let banner: Color = .dynamic(light: Primitives.Darks.dark5, dark: Primitives.Lights.light1)
        public static let tertiary: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.1), dark: Primitives.lightAlpha.opacity(0.1))
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
    }
}

// MARK: - Field

public extension Color.Tangem.Field {
    static let backgroundDefault: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark5)
    static let backgroundFocused: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let textPlaceholder: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
    static let textDefault: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
    static let textDisabled: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
    static let textInvalid: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
    static let borderInvalid: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
    static let iconDefault: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
    static let iconDisabled: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
}

// MARK: - Overlay

public extension Color.Tangem.Overlay {
    static let overlayPrimary: Color = Primitives.Overlays.overlay1
    static let overlaySecondary: Color = Primitives.Overlays.overlay2
}

// MARK: - Fill

public extension Color.Tangem.Fill {
    enum Neutral {
        public static let primary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Base.white)
        public static let primaryInverted: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.Darks.dark6)
        public static let primaryInvertedConstant: Color = Primitives.Base.white
        public static let secondary: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light5)
        public static let tertiaryConstant: Color = Primitives.Darks.dark1
        public static let quaternary: Color = .dynamic(light: Primitives.Lights.light4, dark: Primitives.Darks.dark3)
        public static let bannerBackground: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark5)
    }

    enum Status {
        public static let accent: Color = Primitives.Blue.azure
        public static let warning: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
        public static let attention: Color = .dynamic(light: Primitives.Yellow.tangerine, dark: Primitives.Yellow.mustard)
    }
}

// MARK: - Skeleton

public extension Color.Tangem.Skeleton {
    static let backgroundPrimary: Color = .dynamic(light: Primitives.Lights.light1, dark: Primitives.Darks.dark5)
    /// Skeleton color with sufficient contrast on `Colors.Background.action` backgrounds
    static let backgroundAction: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
}

// MARK: - Markers

public extension Color.Tangem.Markers {
    static let backgroundSolidGray: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.2), dark: Primitives.lightAlpha.opacity(0.2))
    static let backgroundSolidBlue: Color = Primitives.Blue.azure
    static let backgroundSolidRed: Color = Primitives.Red.amaranth
    static let backgroundDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let textGray: Color = .dynamic(light: Primitives.Darks.dark2, dark: Primitives.Lights.light4)
    static let textBlue: Color = Primitives.Blue.azure
    static let textRed: Color = .dynamic(light: Primitives.Red.amaranth, dark: Primitives.Red.flamingo)
    static let textGreen: Color = .dynamic(light: Primitives.Green.eucalyptus, dark: Primitives.Green.emerald)
    static let textDisabled: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Lights.light5)
    static let iconGreen: Color = .dynamic(light: Primitives.Green.eucalyptus, dark: Primitives.Green.emerald)
    static let iconGray: Color = .dynamic(light: Primitives.Darks.dark1, dark: Primitives.Darks.dark2)
    static let iconBlue: Color = Primitives.Blue.azure
    static let iconRed: Color = Primitives.Red.amaranth
    static let iconDisabled: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark5)
    static let borderGray: Color = .dynamic(light: Primitives.Lights.light3, dark: Primitives.lightAlpha.opacity(0.2))
    static let borderTintedBlue: Color = Primitives.Blue.azure.opacity(0.1)
    static let borderTintedRed: Color = Primitives.Red.amaranth.opacity(0.1)
    static let backgroundTintedBlue: Color = Primitives.Blue.azure.opacity(0.1)
    static let backgroundTintedRed: Color = Primitives.Red.amaranth.opacity(0.1)
    static let backgroundTintedGray: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.1), dark: Primitives.lightAlpha.opacity(0.1))
    static let backgroundTintedGreen: Color = .dynamic(light: Primitives.Green.eucalyptus.opacity(0.1), dark: Primitives.Green.emerald.opacity(0.1))
}

// MARK: - Visa

public extension Color.Tangem.Visa {
    static let bannerGradientStart: Color = Primitives.Visa.bannerGradientStart
    static let cardDetailBackground: Color = Primitives.Visa.background
}

private extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        let uiColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        }
        return Color(uiColor: uiColor)
    }
}

// MARK: - Tabs

public extension Color.Tangem.Tabs {
    static let textPrimary: Color = .dynamic(light: Primitives.Lights.light2, dark: Primitives.Darks.dark4)
    static let textSecondary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light5)
    static let textTertiary: Color = .dynamic(light: Primitives.Base.black, dark: Primitives.Base.white)
    static let backgroundPrimary: Color = .dynamic(light: Primitives.Darks.dark6, dark: Primitives.Lights.light1)
    static let backgroundSecondary: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.1), dark: Primitives.lightAlpha.opacity(0.1))
    static let backgroundTertiary: Color = .dynamic(light: Primitives.Base.white, dark: Primitives.lightAlpha.opacity(0.1))
    static let backgroundQuaternary: Color = .dynamic(light: Primitives.darkAlpha.opacity(0.2), dark: Primitives.lightAlpha.opacity(0.1))
}

// MARK: - CardCollection

public extension Color.Tangem.CardCollection {
    private typealias CardCollection = DesignSystemColors.CardCollection

    static let border: Color = .dynamic(
        light: CardCollection.borderLight,
        dark: CardCollection.borderDark
    )

    static let tLogo: Color = .dynamic(
        light: CardCollection.tLogoLight,
        dark: CardCollection.tLogoDark
    )

    static let avrora: Color = .dynamic(
        light: CardCollection.avroraLight,
        dark: CardCollection.avroraDark
    )

    static let tangem = CardCollection.tangem
    static let noteXRP = CardCollection.noteXRP
    static let noteDoge = CardCollection.noteDoge
    static let noteEtherium = CardCollection.noteEtherium
    static let noteBinance = CardCollection.noteBinance
    static let noteCardano = CardCollection.noteCardano
    static let noteBitcoin = CardCollection.noteBitcoin
    static let starts2com = CardCollection.starts2com
    static let wallet1 = CardCollection.wallet1
    static let twins = CardCollection.twins
    static let devkit = CardCollection.devkit
    static let whiteWallet = CardCollection.whiteWallet
    static let shiba = CardCollection.shiba
    static let _37X1 = CardCollection._37X1
    static let bad = CardCollection.bad
    static let kaspa = CardCollection.kaspa
    static let tron = CardCollection.tron
    static let whiteTangem = CardCollection.whiteTangem
    static let dau = CardCollection.dau
    static let dan = CardCollection.dan
    static let trilliant = CardCollection.trilliant
    static let grim = CardCollection.grim
    static let satoshiFriends = CardCollection.satoshiFriends
    static let jr = CardCollection.jr
    static let ve = CardCollection.ve
    static let bitcoinPizzaDay = CardCollection.bitcoinPizzaDay
    static let nwe = CardCollection.nwe
    static let babyDoge = CardCollection.babyDoge
    static let coq = CardCollection.coq
    static let cryptoSeth = CardCollection.cryptoSeth
    static let kishulnu = CardCollection.kishulnu
    static let metrika = CardCollection.metrika
    static let redPanda = CardCollection.redPanda
    static let voltInu = CardCollection.voltInu
    static let kaspaReseller = CardCollection.kaspaReseller
    static let kaspa4 = CardCollection.kaspa4
    static let kaspaNew = CardCollection.kaspaNew
    static let kaspa2 = CardCollection.kaspa2
    static let bitcoinGold = CardCollection.bitcoinGold
    static let pastel = CardCollection.pastel
    static let pastel2 = CardCollection.pastel2
    static let pastel3 = CardCollection.pastel3
    static let kaspa3 = CardCollection.kaspa3
    static let cryptoCasey = CardCollection.cryptoCasey
    static let cryptoOrg = CardCollection.cryptoOrg
    static let stealtCard = CardCollection.stealtCard
    static let btc365 = CardCollection.btc365
    static let kasper = CardCollection.kasper
    static let kaspy = CardCollection.kaspy
    static let neiro = CardCollection.neiro
    static let konan = CardCollection.konan
    static let visa = CardCollection.visa
    static let blushSky = CardCollection.blushSky
    static let blushSky2 = CardCollection.blushSky2
    static let blushSky3 = CardCollection.blushSky3
    static let hyperBlue = CardCollection.hyperBlue
    static let hyperBlue2 = CardCollection.hyperBlue2
    static let hyperBlue3 = CardCollection.hyperBlue3
    static let electraSea = CardCollection.electraSea
    static let electraSea2 = CardCollection.electraSea2
    static let electraSea3 = CardCollection.electraSea3
    static let winterSakura = CardCollection.winterSakura
    static let turbo = CardCollection.turbo
    static let lunar = CardCollection.lunar
    static let springBloom = CardCollection.springBloom
    static let vivid1 = CardCollection.vivid1
    static let vivid2 = CardCollection.vivid2
    static let vivid3 = CardCollection.vivid3
    static let bitcoinPizza = CardCollection.bitcoinPizza
    static let changenow = CardCollection.changenow
    static let chilliz = CardCollection.chilliz
    static let coinMetrika = CardCollection.coinMetrika
    static let getsMine = CardCollection.getsMine
    static let ghoad = CardCollection.ghoad
    static let hodl = CardCollection.hodl
    static let kango = CardCollection.kango
    static let keiro = CardCollection.keiro
    static let kroak = CardCollection.kroak
    static let lockedMoney = CardCollection.lockedMoney
    static let newWorldElite = CardCollection.newWorldElite
    static let passimPay = CardCollection.passimPay
    static let pepeCoin = CardCollection.pepeCoin
    static let ramenCat = CardCollection.ramenCat
    static let rizo = CardCollection.rizo
    static let sakura = CardCollection.sakura
    static let sinCity = CardCollection.sinCity
    static let sunDrop = CardCollection.sunDrop
    static let upbit = CardCollection.upbit
    static let usa = CardCollection.usa
    static let veChain = CardCollection.veChain
    static let vnish = CardCollection.vnish
    static let wildGoat = CardCollection.wildGoat
    static let winter1 = CardCollection.winter1
    static let winter2 = CardCollection.winter2
    static let winter3 = CardCollection.winter3
    static let cashclubgold = CardCollection.cashclubgold
}

// MARK: - Market

public extension Color.Tangem.Market {
    static let textTop1: Color = Primitives.Gold.gold
    static let textTop2: Color = Primitives.Cobalt.cobalt
    static let textTop3: Color = Primitives.Coral.coral

    static let iconTop1: Color = Primitives.Gold.gold
    static let iconTop2: Color = Primitives.Cobalt.cobalt
    static let iconTop3: Color = Primitives.Coral.coral

    static let backgroundTop1: Color = .dynamic(
        light: Primitives.Gold.gold.opacity(0.5),
        dark: Primitives.Gold.gold.opacity(0.3)
    )
    static let backgroundTop2: Color = .dynamic(
        light: Primitives.Cobalt.cobalt.opacity(0.5),
        dark: Primitives.Cobalt.cobalt.opacity(0.3)
    )
    static let backgroundTop3: Color = .dynamic(
        light: Primitives.Coral.coral.opacity(0.5),
        dark: Primitives.Coral.coral.opacity(0.3)
    )
}

// MARK: - Init with hex-value

public extension Color {
    init?(hex: String) {
        let r, g, b, a: Double

        var hexColor = hex.replacingOccurrences(of: "#", with: "")
        if hexColor.count == 6 {
            hexColor += "FF"
        }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            r = Double((hexNumber & 0xff000000) >> 24) / 255
            g = Double((hexNumber & 0x00ff0000) >> 16) / 255
            b = Double((hexNumber & 0x0000ff00) >> 8) / 255
            a = Double(hexNumber & 0x000000ff) / 255

            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
            return
        }

        return nil
    }

    init(hex: String, fallback: Color = .clear) {
        self = Color(hex: hex) ?? fallback
    }
}
