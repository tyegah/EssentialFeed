//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 27/09/22.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
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
    
    private class FeedStoreSpy: FeedStore {
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
            case insert([LocalFeedImage], Date)
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
        func insert(_ localImageFeed:[LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(localImageFeed, timeStamp))
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeInsertionSuccessfully(at index:Int = 0) {
            insertionCompletions[index](nil)
        }
        
    }
}
