//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 13/09/22.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        sut.load{ _ in }
        // Assert
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        sut.load{ _ in }
        sut.load { _ in }
        // Assert
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // This behavior is called stubbing (stubbing error), adding behavior to a class
        // So now we're mixing the spy with a stub behavior, and we should only keep the spy as a spy.
//        client.error = NSError(domain: "", code: 0)
        // And we change the stubbed error with this to keep the spy as a spy, no behavior
        // And this is how the order should be. The completions should be arranged after the sut.load()
        let clientError = NSError(domain: "", code: 0)
        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.connectivity)) {
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200Response() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith:  .failure(RemoteFeedLoader.Error.invalidData)) {
                // Here we create valid json data just to check that even if valid json, if the status code is not 200, we should still deliver error
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200ResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        // Act
        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData)) {
            // arrange
            let invalidJSON = Data("invalidJSON".utf8)
            client.complete(withStatusCode: 200,
                            data: invalidJSON,
                            at: 0)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyList() {
        let (sut, client) = makeSUT()
        
        //act
        expect(sut, toCompleteWith: .success([])) {
            //arrange
            let emptyJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyJSON, at: 0)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithValidJSON() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(id: UUID(),
                             description: nil,
                             location: nil,
                             imageURL: URL(string: "https://a-url.com")!)
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "https://another-url.com")!)
    
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items)) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json, at: 0)
        }
    }
    
    // We need to make sure that when the sut instance is deallocated, the load function will not deliver any result.
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        // arrange
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        // We need to make this sut optional to be able to set it to nil for testing purposes
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        // act
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load() {
            capturedResults.append($0)
        }
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        //assert
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        // the instances of SUT and client should be deallocated after each test
        // So here we need to check for memory leaks and see if each instance is being deallocated
        // The makeSUT is a great place to track for memory leaks
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        // The instance needs to be weak to avoid retain cycle inside the teardown block
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
    // Factory method helpers
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model:FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id,
                            description: description,
                            location: location,
                            imageURL: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if  let value = e.value {
                acc[e.key] = value
            }
        } // This reduce method is to eliminate the nil values inside the dictionary
        // In swift 5, there's a compact map function for this, look it up
        return (item, json)
    }
    
    // Factory method helpers
    private func makeItemsJSON(_ items: [[String:Any]]) -> Data {
        let json = [
            "items": items
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWith expectedResult: RemoteFeedLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        // Act
        // We're now using this expectation and expectedResult, receivedResult data
        // to avoid Equatable protocol conformance on the production code
        // Expectation is used for async process
        // By doing this, we do not overcomplicate the production code with unnecessary protocol comformance
        let exp = expectation(description: "wait for load completion")
        sut.load() { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                // Assert success case
                XCTAssertEqual(receivedItems, expectedItems, file:file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                // Assert failure case
                XCTAssertEqual(receivedError, expectedError, file:file, line: line)
            default:
                XCTFail("Expected \(expectedResult), received \(receivedResult) instead")
            }
            exp.fulfill()
        }
        //arrange
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // Move the test logic to a spy instead
    class HTTPClientSpy: HTTPClient {
        var requestedURLs:[URL] {
            return messages.map { $0.url }
        }
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var error:Error?
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            // We're moving the test logic from the RemoteFeedLoader to HTTPClient
            messages.append((url, completion)) //--> This is the test logic. This is created for testing purposes
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int,
                      data: Data,
                      at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
