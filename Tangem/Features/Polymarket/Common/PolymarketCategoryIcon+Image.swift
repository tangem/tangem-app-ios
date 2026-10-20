//
//  PolymarketCategoryIcon+Image.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemPolymarket

extension PolymarketCategoryIcon {
    var badgeImage: ImageType {
        switch self {
        case .world: DesignSystem.Icons.Earth.regular16
        case .geopolitics: DesignSystem.Icons.GlobeArrow.regular16
        case .elections: DesignSystem.Icons.DocumentPen.regular16
        case .soccer: DesignSystem.Icons.Football.regular16
        case .nba: DesignSystem.Icons.BasketballTurned.regular16
        case .nfl: DesignSystem.Icons.RugbyBall.regular16
        case .hockey: DesignSystem.Icons.Hockey.regular16
        case .tennis: DesignSystem.Icons.Tennis.regular16
        case .formula1: DesignSystem.Icons.CarSports.regular16
        case .tech: DesignSystem.Icons.Monitor.regular16
        case .economy: DesignSystem.Icons.PieChart.regular16
        case .mentions: DesignSystem.Icons.AtSign.regular16
        case .trending: DesignSystem.Icons.ChartAscending.regular16
        case .new: DesignSystem.Icons.New.regular16
        case .politics: DesignSystem.Icons.Government.regular16
        case .sports: DesignSystem.Icons.Basketball.regular16
        case .esports: DesignSystem.Icons.Gamepad.regular16
        case .culture: DesignSystem.Icons.Theater.regular16
        case .weather: DesignSystem.Icons.Weather.regular16
        case .finance: DesignSystem.Icons.Sack.regular16
        case .crypto: DesignSystem.Icons.CoinToken.regular16
        }
    }

    var tabImage: ImageType {
        switch self {
        case .world: DesignSystem.Icons.Earth.regular20
        case .geopolitics: DesignSystem.Icons.GlobeArrow.regular20
        case .elections: DesignSystem.Icons.DocumentPen.regular20
        case .soccer: DesignSystem.Icons.Football.regular20
        case .nba: DesignSystem.Icons.BasketballTurned.regular20
        case .nfl: DesignSystem.Icons.RugbyBall.regular20
        case .hockey: DesignSystem.Icons.Hockey.regular20
        case .tennis: DesignSystem.Icons.Tennis.regular20
        case .formula1: DesignSystem.Icons.CarSports.regular20
        case .tech: DesignSystem.Icons.Monitor.regular20
        case .economy: DesignSystem.Icons.PieChart.regular20
        case .mentions: DesignSystem.Icons.AtSign.regular20
        case .trending: DesignSystem.Icons.ChartAscending.regular20
        case .new: DesignSystem.Icons.New.regular20
        case .politics: DesignSystem.Icons.Government.regular20
        case .sports: DesignSystem.Icons.Basketball.regular20
        case .esports: DesignSystem.Icons.Gamepad.regular20
        case .culture: DesignSystem.Icons.Theater.regular20
        case .weather: DesignSystem.Icons.Weather.regular20
        case .finance: DesignSystem.Icons.Sack.regular20
        case .crypto: DesignSystem.Icons.CoinToken.regular20
        }
    }
}
