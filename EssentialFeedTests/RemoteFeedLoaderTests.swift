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
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200Response() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith:  .failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200ResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        // Act
        expect(sut, toCompleteWith: .failure(.invalidData)) {
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
            let emptyJSON = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyJSON, at: 0)
        }
    }
    
    // MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        // Act
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load() {
            capturedResults.append($0)
        }
        //arrange
        action()
        
        // Assert
        XCTAssertEqual(capturedResults, [result], file:file, line: line)
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
                      data: Data = Data(),
                      at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
