//
//  PromoCampaignContentMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PromoCampaignContentMapper {
    private let valueFormatter: PromoCampaignValueFormatter

    init(valueFormatter: PromoCampaignValueFormatter = PromoCampaignValueFormatter()) {
        self.valueFormatter = valueFormatter
    }

    func map(_ content: PromoCampaignsDTO.Content, payoutTokens: [PromoCampaignsDTO.PayoutToken]) -> PromoCampaignContent {
        let tokenSymbols = Set(payoutTokens.map(\.tokenSymbol))
        let blocks = content.publicDescription.compactMap { mapBlock($0, tokenSymbols: tokenSymbols) }
        let hasBlockLink = blocks.contains { block in
            if case .text(_, _, .some) = block {
                return true
            }

            return false
        }

        return PromoCampaignContent(
            title: content.campaignName,
            subtitle: content.campaignDescription?.nilIfEmpty,
            imageURL: content.publicImage,
            blocks: blocks,
            learnMoreLink: hasBlockLink ? nil : content.learnMoreLink.flatMap(mapLink),
            termsLink: content.tncLink.flatMap(mapLink),
            actionButtonTitle: content.actionButtonName
        )
    }
}

// MARK: - Private

private extension PromoCampaignContentMapper {
    func mapBlock(_ block: PromoCampaignsDTO.ContentBlock, tokenSymbols: Set<String>) -> PromoCampaignContent.Block? {
        switch block {
        case .text(let block):
            return block.text.nilIfEmpty.map { .text(title: block.title?.nilIfEmpty, text: $0, link: block.link.flatMap(mapLink)) }
        case .highlight(let block):
            return block.text.nilIfEmpty.map { .highlight(title: block.title?.nilIfEmpty, text: $0) }
        case .block(let block):
            return block.items.compactMap { mapItem($0, tokenSymbols: tokenSymbols) }.nilIfEmpty.map { .items(title: block.title?.nilIfEmpty, items: $0) }
        case .table(let block):
            return mapTable(block, tokenSymbols: tokenSymbols).map(PromoCampaignContent.Block.table)
        }
    }

    func mapItem(_ item: PromoCampaignsDTO.Item, tokenSymbols: Set<String>) -> PromoCampaignContent.Item? {
        guard let label = item.label.nilIfEmpty else {
            return nil
        }

        switch item.value {
        case .number(let number):
            let value = valueFormatter.format(number, type: item.valueType, currency: item.currency, tokenSymbols: tokenSymbols)
            return PromoCampaignContent.Item(label: label, value: value)
        case .text(let text):
            return text.nilIfEmpty.map { PromoCampaignContent.Item(label: label, value: $0) }
        }
    }

    func mapTable(_ block: PromoCampaignsDTO.TableBlock, tokenSymbols: Set<String>) -> PromoCampaignContent.Table? {
        let headers = block.headers ?? []
        let columnTypes = block.columnTypes ?? []
        let declaredColumnCount = max(headers.count, columnTypes.count)
        let columnCount = declaredColumnCount > 0 ? declaredColumnCount : block.rows.map(\.count).max() ?? 0

        let rows = block.rows
            .map { mapRow($0, columnTypes: columnTypes, columnCount: columnCount, tokenSymbols: tokenSymbols) }
            .filter { $0.contains { !$0.isEmpty } }

        guard rows.isNotEmpty else {
            return nil
        }

        return PromoCampaignContent.Table(
            title: block.title?.nilIfEmpty,
            headers: headers.isEmpty ? [] : (0 ..< columnCount).map { headers[safe: $0] ?? "" },
            rows: rows
        )
    }

    func mapRow(
        _ cells: [PromoCampaignsDTO.TableBlock.Cell],
        columnTypes: [PromoCampaignsDTO.ValueType],
        columnCount: Int,
        tokenSymbols: Set<String>
    ) -> [String] {
        (0 ..< columnCount).map { index in
            guard let cell = cells[safe: index] else {
                return ""
            }

            if let text = cell.text?.nilIfEmpty {
                return text
            }

            guard let value = cell.value else {
                return ""
            }

            return valueFormatter.format(value, type: columnTypes[safe: index], currency: cell.currency, tokenSymbols: tokenSymbols)
        }
    }

    func mapLink(_ link: PromoCampaignsDTO.Link) -> PromoCampaignContent.Link? {
        link.text.nilIfEmpty.map { PromoCampaignContent.Link(title: $0, url: link.url) }
    }
}
