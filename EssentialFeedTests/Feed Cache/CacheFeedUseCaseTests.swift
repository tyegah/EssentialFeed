//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 22/09/22.
//

import XCTest
import EssentialFeed

//** The approach in this TDD is that we didn't define the interface in the beginning (so we didn't create a spy) and uses a class instead. In the end, we're extracting the methods that this class has to create the interface and change the class (FeedStore class) into a spy.

// These tests is driven by the Cache Feed Use Case from BDD specs
class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        // arrange
        let (sut, store) = makeSUT()
        // act
        sut.save(uniqueImageFeed().models) { _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        // arrange
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        // act
        sut.save(uniqueImageFeed().models) { _ in }
        store.completeDeletion(with:deletionError)
        
        // Assert
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    //** This test is removed because it is now redundant (it's already covered on the next test)
//    func test_save_requestsCacheInsertionOnSuccessfulDeletion() {
//        // arrange
//        let items = [uniqueItem(), uniqueItem()]
//        let (sut, store) = makeSUT()
//
//        // act
//        sut.save(items)
//        store.completeDeletionSuccessfully()
//
//        // Assert
//        XCTAssertEqual(store.insertCallCount, 1)
//    }
    
    func test_save_requestsCacheInsertionWithTimeStampOnSuccessfulDeletion() {
        // arrange
        let timeStamp = Date()
        let feed = uniqueImageFeed()
        let (sut, store) = makeSUT(currentDate: { timeStamp })
        
        // act
        sut.save(feed.models) { _ in }
        store.completeDeletionSuccessfully()
        
        // Assert
        //** Now we use only this receivedMessages variable for the assertion
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(feed.locals, timeStamp)])
//        XCTAssertEqual(store.insertions.count, 1)
//        XCTAssertEqual(store.insertions.first?.items, items)
//        XCTAssertEqual(store.insertions.first?.timeStamp, timeStamp)
    }
    
    func test_save_failsOnDeletionError() {
        // arrange
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        // act
        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: deletionError)
        }
//        var receivedError:Error?
//        let exp = expectation(description: "Wait for completion")
//        sut.save(items) { error in
//            receivedError = error
//            exp.fulfill()
//        }
//        store.completeDeletion(with: deletionError)
//        wait(for: [exp], timeout: 1.0)
//        // Assert
//        XCTAssertEqual(deletionError, receivedError as NSError?)
    }
    
    func test_save_failsOnInsertionError() {
        // arrange
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        // act
        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
//        var receivedError:Error?
//        let exp = expectation(description: "Wait for completion")
//        sut.save(items) { error in
//            receivedError = error
//            exp.fulfill()
//        }
//        store.completeDeletionSuccessfully()
//        store.completeInsertion(with: insertionError)
//        wait(for: [exp], timeout: 1.0)
//        // Assert
//        XCTAssertEqual(insertionError, receivedError as NSError?)
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        // arrange
        let (sut, store) = makeSUT()
        
        // act
        expect(sut, toCompleteWith: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
//        var receivedError:Error?
//        let exp = expectation(description: "Wait for completion")
//        sut.save(items) { error in
//            receivedError = error
//            exp.fulfill()
//        }
//        store.completeDeletionSuccessfully()
//        store.completeInsertionSuccessfully()
//        wait(for: [exp], timeout: 1.0)
//        // Assert
//        // Received error should be nil if deletion and insertion are successful
//        XCTAssertNil(receivedError)
    }
    
    
    // This is to handle the crash on the [unowned self] call inside the save method
    // Only for deletion error case
    func test_save_doesNotDeliverDeletionErrorAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        // Make SUT a var because we want to set it to nil
        var sut:LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [LocalFeedLoader.SaveResult]()
        
        sut?.save(uniqueImageFeed().models, completion: { receivedResults.append($0)})
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // Handle instance deallocation for insertion error case
    func test_save_doesNotDeliverInsertionErrorAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        // Make SUT a var because we want to set it to nil
        var sut:LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [LocalFeedLoader.SaveResult]()
        
        sut?.save(uniqueImageFeed().models, completion: { receivedResults.append($0)})
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store:store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedError:Error?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var receivedError:Error?
        let exp = expectation(description: "Wait for completion")
        sut.save(uniqueImageFeed().models) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
        // Assert
        XCTAssertEqual(expectedError as NSError?, receivedError as NSError?,file: file, line: line)
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    private func uniqueImageFeed() -> (models:[FeedImage], locals: [LocalFeedImage]) {
        let imageFeed = [uniqueImage(), uniqueImage()]
        let localImageFeed = imageFeed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
        return (imageFeed, localImageFeed)
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
}
