//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 22/09/22.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store:FeedStore
    private let currentDate: () -> Date
    
    // This currentDate is created with closure because it is not a pure function, which means that
    // Everytime init() is called, it creates a different value
    // So instead of letting the UseCase produce the current date via the impure function (Date.init()) directly
    // We move this responsibility to a collabolator (which is the closure in this case), and inject it as a dependency
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timeStamp: self.currentDate(), completion: completion)
            }
            else {
                completion(error)
            }
        }
    }
}


// Collaborator
class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
//    var deleteCachedFeedCallCount = 0
    var deletionCompletions = [DeletionCompletion]()
    var insertionCompletions = [InsertionCompletion]()
//    var insertions = [(items:[FeedItem], timeStamp: Date)]()
    //** Because the LocalFeedLoader is calling multiple methods of the FeedStore
    //** and they need to be in the right order
    //** We can actually merged the deletion and insertion checks using one variable to guarantee that the received messages are right (which methods are invoke with which values, and in which order)
    //** Thus, we create this variable
    var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage:Equatable {
        case deleteCacheFeed
        case insert([FeedItem], Date)
    }
    
    // delete
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
//        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index:Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index:Int = 0) {
        deletionCompletions[index](nil)
    }
    
    // insert
    func insert(_ items:[FeedItem], timeStamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timeStamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index:Int = 0) {
        insertionCompletions[index](nil)
    }
    
}


// These tests is driven by the Cache Feed Use Case from BDD specs
class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        // arrange
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        // act
        sut.save(items) { _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        // arrange
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        // act
        sut.save(items) { _ in }
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
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timeStamp })
        
        // act
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        // Assert
        //** Now we use only this receivedMessages variable for the assertion
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(items, timeStamp)])
//        XCTAssertEqual(store.insertions.count, 1)
//        XCTAssertEqual(store.insertions.first?.items, items)
//        XCTAssertEqual(store.insertions.first?.timeStamp, timeStamp)
    }
    
    func test_save_failsOnDeletionError() {
        // arrange
        let timeStamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timeStamp })
        let deletionError = anyNSError()
        // act
        var receivedError:Error?
        let exp = expectation(description: "Wait for completion")
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        store.completeDeletion(with: deletionError)
        wait(for: [exp], timeout: 1.0)
        // Assert
        XCTAssertEqual(deletionError, receivedError as NSError?)
    }
    
    func test_save_failsOnInsertionError() {
        // arrange
        let timeStamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timeStamp })
        let insertionError = anyNSError()
        // act
        var receivedError:Error?
        let exp = expectation(description: "Wait for completion")
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        store.completeDeletionSuccessfully()
        store.completeInsertion(with: insertionError)
        wait(for: [exp], timeout: 1.0)
        // Assert
        XCTAssertEqual(insertionError, receivedError as NSError?)
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        // arrange
        let timeStamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT(currentDate: { timeStamp })
        
        // act
        var receivedError:Error?
        let exp = expectation(description: "Wait for completion")
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        store.completeDeletionSuccessfully()
        store.completeInsertionSuccessfully()
        wait(for: [exp], timeout: 1.0)
        // Assert
        // Received error should be nil if deletion and insertion are successful
        XCTAssertNil(receivedError)
    }
    
    // MARK: Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store:store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }
}
