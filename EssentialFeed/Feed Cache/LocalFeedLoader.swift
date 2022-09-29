//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 26/09/22.
//

import Foundation

public final class LocalFeedLoader {
    private let store:FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    // This currentDate is created with closure because it is not a pure function, which means that
    // Everytime init() is called, it creates a different value
    // So instead of letting the UseCase produce the current date via the impure function (Date.init()) directly
    // We move this responsibility to a collabolator (which is the closure in this case), and inject it as a dependency
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            }
            else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [unowned self] result in
            switch result {
            case let .failure(error):
                self.store.deleteCachedFeed(completion: { _ in })
                completion(.failure(error))
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
    
    private var maxCacheAgeInDays:Int {
        return 7
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }
    
    private func cache(_ feed:[FeedImage], with completion: @escaping (Error?) -> Void) {
        store.insert(feed.toLocal(), timeStamp: currentDate()) {[weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return self.map { LocalFeedImage(id: $0.id,
                                        description: $0.description,
                                        location: $0.location,
                                        url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return self.map { FeedImage(id: $0.id,
                                        description: $0.description,
                                        location: $0.location,
                                        url: $0.url) }
    }
}
