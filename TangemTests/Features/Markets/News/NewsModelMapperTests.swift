//
//  NewsModelMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine
import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsModelMapperTests {
    @Test("Maps list item to news item view model")
    func mapsListItemToNewsItemViewModel() async throws {
        let provider = StubNewsReadStatusProvider(readIds: ["1"])
        let mapper = NewsModelMapper(readStatusProvider: provider)
        let item = Self.makeListItem(
            id: 1,
            score: 1.234,
            title: Self.longTitle(),
            categories: [NewsDTO.List.Category(id: 10, name: "Markets")],
            relatedTokens: [
                NewsDTO.List.RelatedToken(id: "btc", symbol: "BTC", name: "Bitcoin"),
                NewsDTO.List.RelatedToken(id: "eth", symbol: "ETH", name: "Ethereum"),
            ]
        )

        let viewModel = await MainActor.run { mapper.toNewsItemViewModel(from: item) }

        #expect(viewModel.score == "1.2")
        #expect(viewModel.title.count == 70)
        #expect(viewModel.title.hasSuffix("..."))
        #expect(viewModel.title == String(Self.longTitle().prefix(67)) + "...")
        #expect(viewModel.isRead == true)
        #expect(viewModel.category == "Markets")
        #expect(viewModel.chips.count == 3)
        #expect(viewModel.chips.first?.title == "Markets")
    }

    @Test("Maps list item to trending news model")
    func mapsListItemToTrendingNewsModel() {
        let provider = StubNewsReadStatusProvider(readIds: ["42"])
        let mapper = NewsModelMapper(readStatusProvider: provider)
        let item = Self.makeListItem(
            id: 42,
            score: 9.99,
            title: "Mapped title",
            categories: [NewsDTO.List.Category(id: 1, name: "Markets")],
            relatedTokens: [NewsDTO.List.RelatedToken(id: "btc", symbol: "BTC", name: "Bitcoin")]
        )

        let model = mapper.mapToNewsModel(from: item)

        #expect(model.id == "42")
        #expect(model.score == 9.99)
        #expect(model.newsUrl == item.newsUrl)
        #expect(model.categories.map(\.name) == ["Markets"])
        #expect(model.relatedTokens.map(\.symbol) == ["BTC"])
        #expect(model.isRead == true)
    }

    @Test("Maps response to carousel items", arguments: Self.carouselCases())
    func mapsResponseToCarouselItems(
        caseName: String,
        readIds: Set<NewsId>,
        expectedReadFlags: [Bool]
    ) {
        let provider = StubNewsReadStatusProvider(readIds: readIds)
        let mapper = NewsModelMapper(readStatusProvider: provider)
        let items = [
            Self.makeListItem(id: 1, score: 6.51, title: "First"),
            Self.makeListItem(id: 2, score: 9.0, title: "Second"),
        ]
        let response = NewsDTO.List.Response(
            meta: NewsDTO.List.Meta(page: 1, limit: 2, total: 2, hasNext: false, asOf: ""),
            items: items
        )

        let carouselItems = mapper.mapCarouselNewsItem(from: response, onTap: { _ in })

        #expect(carouselItems.count == 2, "Case: \(caseName)")
        #expect(carouselItems[0].id == "1", "Case: \(caseName)")
        #expect(carouselItems[0].rating == "6.5", "Case: \(caseName)")
        #expect(carouselItems[0].isRead == expectedReadFlags[0], "Case: \(caseName)")
        #expect(carouselItems[1].id == "2", "Case: \(caseName)")
        #expect(carouselItems[1].rating == "9.0", "Case: \(caseName)")
        #expect(carouselItems[1].isRead == expectedReadFlags[1], "Case: \(caseName)")
    }
}

private extension NewsModelMapperTests {
    final class StubNewsReadStatusProvider: NewsReadStatusProvider {
        private let readIds: Set<NewsId>
        private let subject = PassthroughSubject<NewsId, Never>()

        var readStatusChangedPublisher: AnyPublisher<NewsId, Never> {
            subject.eraseToAnyPublisher()
        }

        init(readIds: Set<NewsId>) {
            self.readIds = readIds
        }

        func isRead(for newsId: NewsId) -> Bool {
            readIds.contains(newsId)
        }

        func markAsRead(newsId: NewsId) {
            subject.send(newsId)
        }
    }

    static func makeListItem(
        id: Int,
        score: Double,
        title: String,
        categories: [NewsDTO.List.Category] = [],
        relatedTokens: [NewsDTO.List.RelatedToken] = []
    ) -> NewsDTO.List.Item {
        NewsDTO.List.Item(
            id: id,
            createdAt: Date(),
            score: score,
            language: "en",
            isTrending: false,
            categories: categories,
            relatedTokens: relatedTokens,
            title: title,
            newsUrl: "https://example.com/\(id)"
        )
    }

    static func longTitle() -> String {
        String(repeating: "A", count: 80)
    }

    static func carouselCases() -> [(String, Set<NewsId>, [Bool])] {
        [
            ("First read, second unread", ["1"], [true, false]),
            ("Both unread", [], [false, false]),
        ]
    }
}
