//
//  PolymarketMarketChannelTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemWebSocket
@testable import TangemPolymarket

@Suite("Polymarket market channel")
struct PolymarketMarketChannelTests {
    @Test("A book gives the highest bid and the lowest ask of every outcome and no last trade")
    func bookGivesBestPricesWithoutLastTrade() throws {
        let updates = try makeSUT().updates(from: .text(Frames.booksOfBothOutcomes))

        #expect(updates == [
            .bestPrices(assetId: AssetIDs.thinNo, bestBid: decimal("0.06"), bestAsk: decimal("0.07"), updatedAt: date(milliseconds: 1_792_419_030_541)),
            .bestPrices(assetId: AssetIDs.thinYes, bestBid: decimal("0.93"), bestAsk: decimal("0.94"), updatedAt: date(milliseconds: 1_792_419_030_541)),
        ])
    }

    @Test("A book with no bids leaves the bid empty")
    func bookWithoutBidsHasNoBid() throws {
        let updates = try makeSUT().updates(from: .text(Frames.bookWithoutBids))

        #expect(updates == [
            .bestPrices(assetId: AssetIDs.oneSided, bestBid: nil, bestAsk: decimal("0.8"), updatedAt: date(milliseconds: 1_791_490_830_000)),
        ])
    }

    @Test("A price change takes the best bid and ask of every changed outcome")
    func priceChangeGivesBestPrices() throws {
        let updates = try makeSUT().updates(from: .text(Frames.priceChange))

        #expect(updates == [
            .bestPrices(assetId: AssetIDs.tradedYes, bestBid: decimal("0.8"), bestAsk: decimal("0.81"), updatedAt: date(milliseconds: 1_792_419_047_199)),
            .bestPrices(assetId: AssetIDs.tradedNo, bestBid: decimal("0.19"), bestAsk: decimal("0.2"), updatedAt: date(milliseconds: 1_792_419_047_199)),
        ])
    }

    @Test("An ask of 1 and a bid of 0 in a price change mean that side of the book is empty")
    func emptySideMarkersMeanNoPrice() throws {
        let updates = try makeSUT().updates(from: .text(Frames.priceChangeWithEmptySides))

        #expect(updates == [
            .bestPrices(assetId: AssetIDs.settledYes, bestBid: decimal("0.999"), bestAsk: nil, updatedAt: date(milliseconds: 1_792_419_041_469)),
            .bestPrices(assetId: AssetIDs.settledNo, bestBid: nil, bestAsk: decimal("0.001"), updatedAt: date(milliseconds: 1_792_419_041_469)),
        ])
    }

    @Test("A last trade event gives the trade price of its own outcome")
    func lastTradeEventGivesItsOwnPrice() throws {
        let updates = try makeSUT().updates(from: .text(Frames.lastTrade))

        #expect(updates == [.lastTrade(assetId: AssetIDs.tradedNo, price: decimal("0.2"), updatedAt: date(milliseconds: 1_792_419_065_848))])
    }

    @Test("Events the feed does not read, a pong and an empty frame give nothing")
    func unknownEventsGiveNothing() throws {
        let sut = makeSUT()

        #expect(try sut.updates(from: .text(Frames.tickSizeChange)).isEmpty)
        #expect(try sut.updates(from: .text("PONG")).isEmpty)
        #expect(try sut.updates(from: .text("")).isEmpty)
    }

    @Test("New best prices keep the last trade the outcome already had")
    func bestPricesKeepThePreviousLastTrade() {
        let previous = quote(bestBid: "0.18", bestAsk: "0.21", lastTradePrice: "0.2")
        let update = PolymarketMarketChannel.Update.bestPrices(assetId: AssetIDs.tradedNo, bestBid: decimal("0.19"), bestAsk: nil, updatedAt: nil)

        let value = makeSUT().value(applying: update, to: previous)

        #expect(value == quote(bestBid: "0.19", bestAsk: nil, lastTradePrice: "0.2"))
    }

    @Test("A new last trade keeps the best bid and ask the outcome already had")
    func lastTradeKeepsThePreviousBestPrices() {
        let previous = quote(bestBid: "0.19", bestAsk: "0.2", lastTradePrice: nil)
        let update = PolymarketMarketChannel.Update.lastTrade(assetId: AssetIDs.tradedNo, price: decimal("0.2"), updatedAt: nil)

        let value = makeSUT().value(applying: update, to: previous)

        #expect(value == quote(bestBid: "0.19", bestAsk: "0.2", lastTradePrice: "0.2"))
    }
}

// MARK: - Helpers

private extension PolymarketMarketChannelTests {
    func makeSUT() -> PolymarketMarketChannel {
        PolymarketMarketChannel()
    }

    func decimal(_ string: String) -> Decimal {
        Decimal(string: string)!
    }

    func date(milliseconds: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }

    func quote(bestBid: String?, bestAsk: String?, lastTradePrice: String?) -> PolymarketOutcomeQuote {
        PolymarketOutcomeQuote(
            assetId: AssetIDs.tradedNo,
            bestBid: bestBid.map(decimal),
            bestAsk: bestAsk.map(decimal),
            lastTradePrice: lastTradePrice.map(decimal),
            updatedAt: nil
        )
    }
}

// MARK: - Fixtures

private enum AssetIDs {
    static let thinNo = "40334269984713198145697159268827872940695103690287352178799202886743022344294"
    static let thinYes = "95953273838584979400804123799092557605425244951940158141202929144897813978861"
    static let oneSided = "97526888801176117954208309908322551659365748413818551820060790873354687454754"
    static let tradedYes = "63433227295278756279641425446159655728811645586370374561215620339701369189369"
    static let tradedNo = "4044794038641740576776561332342408225080351056349669405403587337051575396755"
    static let settledYes = "28399291177697900578074594653499884549279527387459506061446661662266185151728"
    static let settledNo = "132982346976454782410384455871374739365567694547902375713471021951562522404"
}

private enum Frames {
    static let booksOfBothOutcomes = #"[{"market":"0xfdacaa629ea64c3047fd4ab5675568e781f16d9298bd080c1e8a8b0e7779c783","asset_id":"40334269984713198145697159268827872940695103690287352178799202886743022344294","timestamp":"1792419030541","hash":"54a3696ae805b023112920a18da5529fc5f714a6","bids":[{"price":"0.01","size":"12284.37"},{"price":"0.02","size":"62761.4"},{"price":"0.03","size":"13106.89"},{"price":"0.04","size":"49404.24"},{"price":"0.05","size":"21233.44"},{"price":"0.06","size":"6748.54"}],"asks":[{"price":"0.99","size":"700"},{"price":"0.9","size":"70"},{"price":"0.79","size":"14"},{"price":"0.77","size":"30.43"},{"price":"0.75","size":"12"},{"price":"0.72","size":"7.14"},{"price":"0.7","size":"10"},{"price":"0.55","size":"15.55"},{"price":"0.37","size":"50000"},{"price":"0.34","size":"147.06"},{"price":"0.16","size":"2024.9"},{"price":"0.14","size":"10"},{"price":"0.13","size":"485"},{"price":"0.12","size":"2254"},{"price":"0.11","size":"2799.67"},{"price":"0.1","size":"10738"},{"price":"0.09","size":"12646.67"},{"price":"0.08","size":"38226.28"},{"price":"0.07","size":"3300.39"}],"tick_size":"0.01","event_type":"book","last_trade_price":"0.930"},{"market":"0xfdacaa629ea64c3047fd4ab5675568e781f16d9298bd080c1e8a8b0e7779c783","asset_id":"95953273838584979400804123799092557605425244951940158141202929144897813978861","timestamp":"1792419030541","hash":"39699241ab1e0fd8f65e640a1ab154708bc5719c","bids":[{"price":"0.01","size":"700"},{"price":"0.1","size":"70"},{"price":"0.21","size":"14"},{"price":"0.23","size":"30.43"},{"price":"0.25","size":"12"},{"price":"0.28","size":"7.14"},{"price":"0.3","size":"10"},{"price":"0.45","size":"15.55"},{"price":"0.63","size":"50000"},{"price":"0.66","size":"147.06"},{"price":"0.84","size":"2024.9"},{"price":"0.86","size":"10"},{"price":"0.87","size":"485"},{"price":"0.88","size":"2254"},{"price":"0.89","size":"2799.67"},{"price":"0.9","size":"10738"},{"price":"0.91","size":"12646.67"},{"price":"0.92","size":"38226.28"},{"price":"0.93","size":"3300.39"}],"asks":[{"price":"0.99","size":"12284.37"},{"price":"0.98","size":"62761.4"},{"price":"0.97","size":"13106.89"},{"price":"0.96","size":"49404.24"},{"price":"0.95","size":"21233.44"},{"price":"0.94","size":"6748.54"}],"tick_size":"0.01","event_type":"book","last_trade_price":"0.930"}]"#

    static let bookWithoutBids = #"{"market":"0x36dc2a0c6c1974d3d6d953f763d5d9fdc744889f8a870ec0f12ab371c2afd2f5","asset_id":"97526888801176117954208309908322551659365748413818551820060790873354687454754","timestamp":"1791490830000","hash":"11b11c033debbea1eb17a57379e4688c6fd57fe6","bids":[],"asks":[{"price":"0.8","size":"5"}],"tick_size":"0.01","event_type":"book","last_trade_price":""}"#

    static let priceChange = #"{"market":"0xe79f1759cfd4a2fbf802b900f548c284ea52273c1d55cf1ee848e8609d03494a", "price_changes":[{"asset_id":"63433227295278756279641425446159655728811645586370374561215620339701369189369", "price":"0.6", "size":"0", "side":"BUY", "hash":"c46acdd5bbedeaa71d73a2adeb21f4ab42e194cf", "best_bid":"0.8", "best_ask":"0.81"}, {"asset_id":"4044794038641740576776561332342408225080351056349669405403587337051575396755", "price":"0.4", "size":"0", "side":"SELL", "hash":"384f978debb8553977273ac2ffa6e52b304c84bc", "best_bid":"0.19", "best_ask":"0.2"}], "timestamp":"1792419047199", "event_type":"price_change"}"#

    static let priceChangeWithEmptySides = #"{"market":"0xb2a0564930400c82892ba2ce9a9f7eaa4b42af3c52659fa4e6cc7643a871be5c", "price_changes":[{"asset_id":"28399291177697900578074594653499884549279527387459506061446661662266185151728", "price":"0.07", "size":"0", "side":"BUY", "hash":"c159a94d13b6d91c2a117ec7007a50e4e214808d", "best_bid":"0.999", "best_ask":"1"}, {"asset_id":"132982346976454782410384455871374739365567694547902375713471021951562522404", "price":"0.93", "size":"0", "side":"SELL", "hash":"3fc1c374a028cbabf9650371614fdf20acc8fdd4", "best_bid":"0", "best_ask":"0.001"}], "timestamp":"1792419041469", "event_type":"price_change"}"#

    static let lastTrade = #"{"market":"0xe79f1759cfd4a2fbf802b900f548c284ea52273c1d55cf1ee848e8609d03494a", "asset_id":"4044794038641740576776561332342408225080351056349669405403587337051575396755", "price":"0.2", "size":"25", "fee_rate_bps":"0", "side":"BUY", "timestamp":"1792419065848", "event_type":"last_trade_price", "transaction_hash":"0x583aeba896c92a20983a3603dd49e4b4ee75f0e4567ec07deac04705730dfb94"}"#

    static let tickSizeChange = #"{"event_type":"tick_size_change","asset_id":"4044794038641740576776561332342408225080351056349669405403587337051575396755","market":"0xe79f1759cfd4a2fbf802b900f548c284ea52273c1d55cf1ee848e8609d03494a","old_tick_size":"0.01","new_tick_size":"0.001","timestamp":"1792419070000"}"#
}
