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


