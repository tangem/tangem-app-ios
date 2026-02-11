//
//  NewsLikeServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsLikeServiceTests {
    @Test("Toggle like updates state")
    func toggleLikeUpdatesState() {
        let service = InMemoryNewsLikeService()

        #expect(service.isLiked(newsId: 1) == false)

        service.toggleLike(newsId: 1)
        #expect(service.isLiked(newsId: 1) == true)

        service.toggleLike(newsId: 1)
        #expect(service.isLiked(newsId: 1) == false)
    }
}
