//
//  ShtorkaShowcaseMocks.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct ShtorkaMockWidgetsRow: View {
    private let accentBlue = Color(red: 0.23, green: 0.49, blue: 1.0)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                smallTilesColumn
                earningTile
                visaTile
            }
            .padding(.horizontal, 16)
        }
    }

    private var smallTilesColumn: some View {
        VStack(spacing: 8) {
            smallTile("For you") {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.56, green: 0.36, blue: 0.96),
                                    Color(red: 0.33, green: 0.83, blue: 0.54),
                                    Color(red: 1.0, green: 0.62, blue: 0.34),
                                    Color(red: 0.56, green: 0.36, blue: 0.96),
                                ],
                                center: .center
                            )
                        )

                    Circle()
                        .fill(Color(red: 0.09, green: 0.09, blue: 0.11))
                        .padding(4)
                }
                .frame(width: 24, height: 24)
            }

            smallTile("Add account") {
                Circle()
                    .fill(accentBlue)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    }
            }
        }
    }

    private func smallTile(_ title: String, @ViewBuilder icon: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            icon()

            Spacer(minLength: 0)

            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 120, height: 86, alignment: .leading)
        .tangemMaterialSurface(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var earningTile: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentBlue)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "percent")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    }

                Spacer(minLength: 8)

                Circle()
                    .fill(Color(red: 0.16, green: 0.17, blue: 0.19))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    }
            }

            Spacer(minLength: 0)

            Text("Start earning")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)

            Text("Increase your investments with max potential")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            HStack(spacing: 4) {
                Text("$56")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background {
                        Capsule()
                            .fill(accentBlue)
                    }

                Text("yearly")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(width: 188, height: 180, alignment: .leading)
        .tangemMaterialSurface(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var visaTile: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.36, green: 0.29, blue: 0.87))
                .frame(width: 36, height: 36)
                .overlay {
                    Text("VISA")
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 3)
                }

            Spacer(minLength: 0)

            Text("Tangem Pay")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)

            Text("Apply for card")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .padding(.top, 2)

            HStack(spacing: 4) {
                Text("5% cashback")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                Text("$100")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            }
            .lineLimit(1)
            .padding(.top, 2)
        }
        .padding(12)
        .frame(width: 188, height: 180, alignment: .leading)
        .tangemMaterialSurface(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

enum ShtorkaMockTab: CaseIterable, Hashable {
    case crypto
    case realAssets
    case earn
    case predictions

    var title: String {
        switch self {
        case .crypto: "Crypto"
        case .realAssets: "Real assets"
        case .earn: "Earn"
        case .predictions: "Predictions"
        }
    }

    var icon: String {
        switch self {
        case .crypto: "circle.circle"
        case .realAssets: "building.columns"
        case .earn: "person.2"
        case .predictions: "sparkles"
        }
    }
}

struct ShtorkaMockTabChips: View {
    @Binding var selected: ShtorkaMockTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ShtorkaMockTab.allCases, id: \.self) { tab in
                    SwiftUI.Button {
                        selected = tab
                    } label: {
                        chipView(tab)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chipView(_ tab: ShtorkaMockTab) -> some View {
        HStack(spacing: 6) {
            Image(systemName: tab.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tab == selected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary)

            Text(tab.title)
                .style(
                    DesignSystem.Font.subheadingMediumToken,
                    color: tab == selected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textSecondary
                )
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background {
            if tab == selected {
                Capsule()
                    .fill(DesignSystem.Color.bgTertiary)
            }
        }
    }
}

struct ShtorkaMockBanner: View {
    var onAction: () -> Void = {}

    private let cardShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        VStack(spacing: 10) {
            card
            pager
        }
        .padding(.horizontal, 16)
    }

    private var card: some View {
        VStack(spacing: 12) {
            header
            actions
        }
        .padding(14)
        .tangemMaterialSurface(in: cardShape)
        .overlay {
            cardShape
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
        .glowRing(.magic, size: .card(cornerRadius: 20))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Color.bgAccentBlue)

                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Banner title")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text("Description")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .fill(DesignSystem.Color.bgTransparentSecondary)

                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
            .frame(width: 24, height: 24)
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Text("Label")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(DesignSystem.Color.bgTertiary, in: Capsule())

            SwiftUI.Button(action: onAction) {
                Text("Label")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textInversePrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(DesignSystem.Color.bgInverse, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var pager: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 4) { index in
                Circle()
                    .fill(index == 0 ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

struct ShtorkaMockMarketCap: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 8) {
                metricCard(
                    title: "Fear & greed",
                    status: "Extreme Fear",
                    statusColor: DesignSystem.Color.textAccentOrange,
                    value: "13",
                    progress: 0.15
                )

                metricCard(
                    title: "Altcoin index",
                    status: "Altcoin Growth",
                    statusColor: DesignSystem.Color.textAccentGreen,
                    value: "56",
                    progress: 0.55
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total market cap")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$ 2.44 T")
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(DesignSystem.Color.textAccentBlue)

                    Text("1,18%")
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentBlue)
                }
            }
        }
    }

    private func metricCard(
        title: String,
        status: String,
        statusColor: Color,
        value: String,
        progress: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)

            Text(status)
                .style(DesignSystem.Font.captionMediumToken, color: statusColor)
                .padding(.top, 2)

            Text(value)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .padding(.top, 4)

            Spacer(minLength: 4)

            indexTrack(progress: progress)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignSystem.Color.bgSecondary)
        }
    }

    private func indexTrack(progress: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Color.iconAccentRed,
                                DesignSystem.Color.iconAccentOrange,
                                DesignSystem.Color.iconAccentYellow,
                                DesignSystem.Color.iconAccentGreen,
                                Color(red: 0.25, green: 0.5, blue: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 4)

                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .offset(x: proxy.size.width * progress - 5)
            }
        }
        .frame(height: 10)
    }
}

struct ShtorkaMockMarketPulse: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Pulse")
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.horizontal, 16)

            controls
                .padding(.horizontal, 16)

            filters

            tokenList
                .padding(.horizontal, 16)
        }
    }

    private var controls: some View {
        HStack {
            HStack(spacing: 4) {
                Text("Categories")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DesignSystem.Color.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(DesignSystem.Color.bgTertiary, in: Capsule())

            Spacer()

            HStack(spacing: 16) {
                Text("Day")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(DesignSystem.Color.bgTertiary, in: Capsule())

                Text("Week")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textTertiary)

                Text("Month")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textTertiary)
            }
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Market cap")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 32)
                    .background(DesignSystem.Color.bgTertiary, in: Capsule())

                ForEach(["Top gainers", "Top losers", "Experienced"], id: \.self) { title in
                    Text(title)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textTertiary)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var tokenList: some View {
        VStack(spacing: 0) {
            ForEach(ShtorkaMockToken.samples) { token in
                NavigationLink(value: token) {
                    ShtorkaMockMarketPulseRow(token: token)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ShtorkaMockMarketPulseRow: View {
    let token: ShtorkaMockToken

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(token.iconBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: token.iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(token.name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(token.symbol)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textTertiary)
                }

                HStack(spacing: 6) {
                    Text(token.rank)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .frame(width: 16, height: 16)
                        .background(DesignSystem.Color.bgTertiary, in: RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Text(token.marketCap)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(token.price)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: token.isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(changeColor)

                    Text(token.change)
                        .style(DesignSystem.Font.captionMediumToken, color: changeColor)
                }
            }

            ShtorkaMockMarketPulseSparkline(seed: token.seed)
        }
        .frame(height: 64)
    }

    private var changeColor: Color {
        token.isPositive ? DesignSystem.Color.textAccentBlue : DesignSystem.Color.textAccentRed
    }
}

private struct ShtorkaMockMarketPulseSparkline: View {
    let seed: Int
    var width: CGFloat = 44
    var height: CGFloat = 18
    var lineWidth: CGFloat = 1.5

    var body: some View {
        Path { path in
            let values: [CGFloat] = [0.72, 0.58, 0.66, 0.48, 0.56, 0.40, 0.50, 0.34, 0.42, 0.24, 0.30, 0.16]
            let jitter = CGFloat(seed) * 0.05
            let stepX: CGFloat = width / CGFloat(values.count - 1)

            for (index, value) in values.enumerated() {
                let shifted = value + (index.isMultiple(of: 2) ? jitter : -jitter)
                let y = min(max(shifted, 0.06), 0.94) * height
                let point = CGPoint(x: CGFloat(index) * stepX, y: y)

                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(
            Color(red: 0.35, green: 0.55, blue: 1),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
        .frame(width: width, height: height)
    }
}

struct ShtorkaMockToken: Identifiable, Hashable {
    let iconName: String
    let iconRed: Double
    let iconGreen: Double
    let iconBlue: Double
    let name: String
    let symbol: String
    let rank: String
    let marketCap: String
    let price: String
    let change: String
    let isPositive: Bool
    let seed: Int

    var id: String { symbol }

    var iconBackground: Color {
        Color(red: iconRed, green: iconGreen, blue: iconBlue)
    }

    static var samples: [ShtorkaMockToken] {
        [
            ShtorkaMockToken(iconName: "bitcoinsign", iconRed: 0.95, iconGreen: 0.58, iconBlue: 0.16, name: "Bitcoin", symbol: "BTC", rank: "1", marketCap: "1.196T", price: "$59,723.24", change: "2.08%", isPositive: true, seed: 0),
            ShtorkaMockToken(iconName: "diamond.fill", iconRed: 0.48, iconGreen: 0.47, iconBlue: 0.62, name: "Ethereum", symbol: "ETH", rank: "2", marketCap: "$352.899 B", price: "$2,922", change: "2.08%", isPositive: true, seed: 1),
            ShtorkaMockToken(iconName: "dollarsign", iconRed: 0.15, iconGreen: 0.63, iconBlue: 0.48, name: "Tether", symbol: "USDT", rank: "3", marketCap: "$187.116 B", price: "$0,9988", change: "2.08%", isPositive: false, seed: 2),
        ]
    }
}

struct ShtorkaMockTokenDetail: View {
    let token: ShtorkaMockToken
    @Binding var isModalPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Circle()
                    .fill(token.iconBackground)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: token.iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(token.name)
                        .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(token.symbol)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(token.price)
                    .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: token.isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(changeColor)

                    Text(token.change)
                        .style(DesignSystem.Font.bodyMediumToken, color: changeColor)
                }
            }

            ShtorkaMockMarketPulseSparkline(seed: token.seed, width: 340, height: 120, lineWidth: 2)
                .frame(maxWidth: .infinity)

            SwiftUI.Button("Present modal from pushed screen") { isModalPresented = true }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.Color.bgPrimary)
        .navigationTitle(token.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var changeColor: Color {
        token.isPositive ? DesignSystem.Color.textAccentBlue : DesignSystem.Color.textAccentRed
    }
}

struct ShtorkaMockRealAssets: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real assets")
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(Self.assets) { asset in
                    NavigationLink(value: asset) {
                        assetRow(
                            symbol: asset.symbol,
                            name: asset.name,
                            price: asset.price,
                            change: asset.change,
                            isPositive: asset.isPositive,
                            color: asset.iconBackground
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private static var assets: [ShtorkaMockToken] {
        [
            ShtorkaMockToken(iconName: "building.columns", iconRed: 0.55, iconGreen: 0.55, iconBlue: 0.6, name: "Apple", symbol: "AAPL", rank: "1", marketCap: "$3.4 T", price: "$234.10", change: "1.2%", isPositive: true, seed: 3),
            ShtorkaMockToken(iconName: "building.columns", iconRed: 0.85, iconGreen: 0.68, iconBlue: 0.25, name: "Gold", symbol: "OZ", rank: "2", marketCap: "$16 T", price: "$2,411", change: "0.4%", isPositive: true, seed: 4),
            ShtorkaMockToken(iconName: "building.columns", iconRed: 0.8, iconGreen: 0.25, iconBlue: 0.3, name: "Tesla", symbol: "TSLA", rank: "3", marketCap: "$1.0 T", price: "$312.44", change: "2.1%", isPositive: false, seed: 5),
        ]
    }

    private func assetRow(symbol: String, name: String, price: String, change: String, isPositive: Bool, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String(symbol.prefix(1)))
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(symbol)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(price)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(isPositive ? DesignSystem.Color.textAccentBlue : DesignSystem.Color.textAccentRed)

                    Text(change)
                        .style(DesignSystem.Font.captionMediumToken, color: isPositive ? DesignSystem.Color.textAccentBlue : DesignSystem.Color.textAccentRed)
                }
            }
        }
        .frame(height: 64)
    }
}

struct ShtorkaMockEarn: View {
    var onOfferTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earn")
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            SwiftUI.Button(action: onOfferTap) {
                offerCard(title: "USDT Lending", apy: "12.1% APY", icon: "dollarsign.circle.fill", color: Color(red: 0.15, green: 0.63, blue: 0.48))
            }
            .buttonStyle(.plain)

            SwiftUI.Button(action: onOfferTap) {
                offerCard(title: "ETH Staking", apy: "4.5% APY", icon: "diamond.fill", color: Color(red: 0.48, green: 0.47, blue: 0.62))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    private func offerCard(title: String, apy: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(apy)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentGreen)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
        .padding(12)
        .tangemMaterialSurface(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ShtorkaMockPredictions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Predictions")
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            predictionCard(question: "Bitcoin above $100K by 2027?", yes: "Yes 62¢", no: "No 38¢")
            predictionCard(question: "ETH flips BTC this cycle?", yes: "Yes 9¢", no: "No 91¢")
        }
        .padding(.horizontal, 16)
    }

    private func predictionCard(question: String, yes: String, no: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            HStack(spacing: 8) {
                Text(yes)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textAccentGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(DesignSystem.Color.bgTertiary, in: Capsule())

                Text(no)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textAccentRed)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(DesignSystem.Color.bgTertiary, in: Capsule())
            }
        }
        .padding(14)
        .tangemMaterialSurface(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
#endif
