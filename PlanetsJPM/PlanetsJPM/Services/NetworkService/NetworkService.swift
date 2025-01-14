//
//  Networkservice.swift
//  PlanetsJPM
//
//  Created by Dionisis Chatzimarkakis on 18/11/24.
//

import Foundation
import Network

protocol NetworkServiceProtocol {
    
    func request<T: Decodable>(endpoint: APIEndpoint?,
                               endpointUrlString: String?,
                               body: Data?) async throws -> T
}

class NetworkService: ObservableObject, NetworkServiceProtocol {

    static let shared = NetworkService()
                
    func request<T: Decodable>(endpoint: APIEndpoint?,
                               endpointUrlString: String? = nil,
                               body: Data? = nil) async throws -> T {
        
        
        var request: URLRequest?

        // Ensure the URL is valid
        if let endpoint = endpoint,
           let url = endpoint.url {
            request = URLRequest(url: url)
            request?.httpMethod = endpoint.method.rawValue
        } else {
            if let endpointStr = endpointUrlString,
               let urlObj = URL(string: endpointStr) {
                request = URLRequest(url: urlObj)
                request?.httpMethod = HTTPMethod.GET.rawValue
            }
        }
     
        guard var request = request else {
            throw NetworkError.badURL
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        
        // Create a URLSession with custom timeout
        let urlconfig = URLSessionConfiguration.default
        urlconfig.timeoutIntervalForRequest = 15
        urlconfig.timeoutIntervalForResource = 20
        let session = URLSession(configuration: urlconfig)
        
        let (data, response) = try await session.data(for: request)
        
        // Check the HTTP response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
                
        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch DecodingError.dataCorrupted(let context) {
            debugPrint("Decoding error: \(context.debugDescription)")
            throw NetworkError.decodingError
        } catch DecodingError.keyNotFound(let key, let context) {
            debugPrint("Decoding error: \(key.stringValue) was not found, \(context.debugDescription)")
            throw NetworkError.decodingError
        } catch DecodingError.typeMismatch(let type, let context) {
            debugPrint("Decoding error: \(type) was expected, \(context.debugDescription)")
            throw NetworkError.decodingError
        } catch DecodingError.valueNotFound(let type, let context) {
            debugPrint("Decoding error: no value was found for \(type), \(context.debugDescription)")
            throw NetworkError.decodingError
        } catch {
            print("I know not this error")
            throw NetworkError.decodingError
        }
             
    }

}

