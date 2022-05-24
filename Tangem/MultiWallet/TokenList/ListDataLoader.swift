//
//  ListDataLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol ListDataLoaderDelegate: AnyObject {
    func filter(_ model: CoinModel) -> CoinModel?
}

class ListDataLoader: ObservableObject {
    // MARK: Output
    @Published var items: [CoinModel] = []
    
    // Tells if all records have been loaded. (Used to hide/show activity spinner)
    private(set) var canFetchMore = true
    
    weak var delegate: ListDataLoaderDelegate? = nil
    
    // MARK: Input

    private let isTestnet: Bool
    private let coinsService: CoinsService
    
    // MARK: Private
    
    // Tracks last page loaded. Used to load next page (current + 1)
    private var currentPage = 0
    
    // Limit of records per page. (Only if backend supports, it usually does)
    private let perPage = 20
    
    private var cancellable: AnyCancellable?
    private var currentRequests: [String: AnyCancellable?] = [:]
    
    private var cached: [CoinModel] = []
    private var cachedSearch: [String: [CoinModel]] = [:]
    private var lastSearchText = ""
    
    private var loadFromLocalPublisher: AnyPublisher<[CoinModel], Never> {
        SupportedTokenItems().loadCoins(isTestnet: isTestnet)
            .map { [weak self] models -> [CoinModel] in
                models.compactMap { self?.delegate?.filter($0) }
            }
            .handleEvents(receiveOutput: { [weak self] output in
                self?.cached = output
            })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    private var cacheFromLocalPublisher: AnyPublisher<[CoinModel], Never> {
        Just(cached).eraseToAnyPublisher()
    }
    
    init(isTestnet: Bool, coinsService: CoinsService) {
        self.isTestnet = isTestnet
        self.coinsService = coinsService
    }
    
    func reset(_ searchText: String) {
        self.canFetchMore = true
        self.items = []
        self.currentPage = 0
        self.lastSearchText = searchText
        self.cachedSearch = [:]
    }
    
    func fetch(_ searchText: String) {
        cancellable = nil
        
        if lastSearchText != searchText {
            reset(searchText)
        }
     
        cancellable = loadItems(searchText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                
                self.currentPage += 1
                self.items.append(contentsOf: items)
                // If count of data received is less than perPage value then it is last page.
                if items.count < self.perPage {
                    self.canFetchMore = false
                }
        }
    }
}

// MARK: Private

private extension ListDataLoader {
    func loadItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        if isTestnet || !searchText.isEmpty {
            return loadTestnetItems(searchText)
        }
        
        let pageModel = PageModel(limit: perPage, offset: items.count)
        
        return coinsService.loadTokens(pageModel: pageModel)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    func loadTestnetItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        let searchText = searchText.lowercased()
        let itemsPublisher = cached.isEmpty ? loadFromLocalPublisher : cacheFromLocalPublisher
        
        return itemsPublisher
            .map { [weak self] models -> [CoinModel] in
                guard let self = self else { return [] }
                
                if searchText.isEmpty { return models }
                
                if let cachedSearch = self.cachedSearch[searchText] {
                    return cachedSearch
                }
             
                let foundItems = models.filter {
                    "\($0.name) \($0.symbol)".lowercased().contains(searchText)
                }
                
                self.cachedSearch[searchText] = foundItems
                
                return foundItems
            }
            .map { [weak self] models -> [CoinModel] in
                self?.getPage(for: models) ?? []
            }
            .eraseToAnyPublisher()
    }
    
    func getPage(for items: [CoinModel]) -> [CoinModel] {
        Array(items.dropFirst(currentPage * perPage).prefix(perPage))
    }
}
