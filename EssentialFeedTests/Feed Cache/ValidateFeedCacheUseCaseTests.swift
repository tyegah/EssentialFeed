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
    
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheFeed])
    }
    
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeleteLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = uniqueImageFeed()
        
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        sut.validateCache()
        store.completeRetrieval(with: feed.locals, timestamp: lessThanSevenDaysOldTimeStamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    // MARK: Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store:store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func uniqueImageFeed() -> (models:[FeedImage], locals: [LocalFeedImage]) {
        let imageFeed = [uniqueImage(), uniqueImage()]
        let localImageFeed = imageFeed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
        return (imageFeed, localImageFeed)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
