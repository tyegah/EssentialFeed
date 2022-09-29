//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 29/09/22.
//

import XCTest
import EssentialFeed

//** This Validate Feed Cache Use Case is created because:
//**    On the Load Feed Cache function, we violate the query/command principle
//**    which means that the query (getting data from cache) ideally should not have a side effect
//**    but we included the deletion (delete cache when it's expired on load) inside the load/query function
//**    and deletion causes side effects (it alters the data).
//**    so, it is best to separate the two concerns which is the load function and the validation of the feed cache function.

class ValidateFeedCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    // MARK: Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store:store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
