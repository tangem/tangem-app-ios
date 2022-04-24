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
    func map(_ model: CoinModel) -> CoinViewModel
    func filter(_ model: CoinModel) -> CoinModel?
}

class ListDataLoader: ObservableObject {
    @Published var items = [CoinViewModel]()
    
    // Tells if all records have been loaded. (Used to hide/show activity spinner)
    private(set) var canFetchMore = true
    // Tracks last page loaded. Used to load next page (current + 1)
    private(set) var currentPage = 0
    // Limit of records per page. (Only if backend supports, it usually does)
    let perPage = 20
    
    let isTestnet: Bool
    
    weak var delegate: ListDataLoaderDelegate? = nil
    
    private var cancellable: AnyCancellable?
    private var cached: [CoinModel] = []
    private var cachedSearch: [String: [CoinModel]] = [:]
    private var lastSearchText = ""
    
    private var loadPublisher: AnyPublisher<[CoinModel], Never> {
        SupportedTokenItems().loadCoins(isTestnet: isTestnet)
            .map{[weak self] models -> [CoinModel] in
                models.compactMap { self?.delegate?.filter($0) }
            }
            .handleEvents(receiveOutput: {[weak self] output in
                self?.cached = output
            })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    private var cachePublisher: AnyPublisher<[CoinModel], Never> {
        Just(cached).eraseToAnyPublisher()
    }
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
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
            .map {[weak self] items -> [CoinViewModel] in
                return items.compactMap { self?.delegate?.map($0) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                
                self.currentPage += 1
                self.items.append(contentsOf: $0)
                // If count of data received is less than perPage value then it is last page.
                if $0.count < self.perPage {
                    self.canFetchMore = false
                }
        }
    }
    
    private func loadItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        let searchText = searchText.lowercased()
        let itemsPublisher = cached.isEmpty ? loadPublisher : cachePublisher
        
        return itemsPublisher
            .map {[weak self] models -> [CoinModel] in
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
            .map {[weak self] models -> [CoinModel] in
                self?.getPage(for: models) ?? []
            }
            .eraseToAnyPublisher()
    }
    
    private func getPage(for items: [CoinModel]) -> [CoinModel] {
        Array(items.dropFirst(currentPage*perPage).prefix(perPage))
    }
}


