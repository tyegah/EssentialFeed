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
        // Act
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load() {
            capturedErrors.append($0)
        }
        
        // This behavior is called stubbing (stubbing error), adding behavior to a class
        // So now we're mixing the spy with a stub behavior, and we should only keep the spy as a spy.
//        client.error = NSError(domain: "", code: 0)
        // And we change the stubbed error with this to keep the spy as a spy, no behavior
        // And this is how the order should be. The completions should be arranged after the sut.load()
        let clientError = NSError(domain: "", code: 0)
        client.complete(with: clientError)
       
        // Assert
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200Response() {
        // Arrange
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        // Act
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load() {
            capturedErrors.append($0)
        }
        
        let clientError = NSError(domain: "", code: 0)
        client.complete(withStatusCode: 400)
       
        // Assert
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    // MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    // Move the test logic to a spy instead
    class HTTPClientSpy: HTTPClient {
        var requestedURLs:[URL] {
            return messages.map { $0.url }
        }
        var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
        var error:Error?
        
        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            // We're moving the test logic from the RemoteFeedLoader to HTTPClient
            messages.append((url, completion)) //--> This is the test logic. This is created for testing purposes
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }
        
        func complete(withStatusCode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(nil, response)
        }
    }
}
