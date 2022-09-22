//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 22/09/22.
//

import XCTest

class LocalFeedLoader {
    let store:FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
}


// Collaborator
class FeedStore {
    var deleteCachedFeedCallCount = 0
}

class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store:store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
