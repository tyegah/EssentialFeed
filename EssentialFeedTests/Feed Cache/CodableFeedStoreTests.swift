//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 03/10/22.
//

import XCTest
import EssentialFeed

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    // This setup method is needed to clean up the artifacts from previously run tests
    // But the storeURL is a detail that tests shouldn't know about
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        // The store url needs to be explicit to make the correlation clearer between the given, when, then
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        assertThatRetrieveHasNoSideEffectsONFailure(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut) 
    }
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    // checking error on invalid store url
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to: sut)
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        let deletionError = deleteCacheFeed(from: sut)
        XCTAssertNotNil(deletionError, "Expected deletion to fail with an error")
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        deleteCacheFeed(from: sut)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        assertThatSideEffectsRunSerially(on: sut)
    }
    
    // MARK: Helpers
    private func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
