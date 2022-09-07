//
//  API.swift
//  APITests
//
//  Created by Charlie Rick on 2022-08-30.
//

import Foundation
import Combine

struct API {
  static let baseURLString = "https://pokeapi.co/api/v2/"
  static let scheduler = DispatchQueue.main
  static let jsonDecoder: JSONDecoder = {
    var decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
  
  enum Endpoint {
    case pokedex(String)
    
    var path: String {
      switch self {
      case .pokedex(let name):
        return "pokedex/\(name)"
      }
    }
  }
  
  enum APIError: Error {
    case invalidURL
    case requestError
    case uncompatibleiOS
  }
  
  static func request<T: Decodable>(endpoint: Endpoint) async throws -> (data: T, response: URLResponse) {
    // iOS 15
    guard #available(iOS 15, *) else {
      throw APIError.uncompatibleiOS
    }
    guard let url = URL(string: API.baseURLString + endpoint.path) else {
      throw APIError.invalidURL
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    print(T.self)
    try? debugPrint(response: response, data: data)
    let decodedData = try jsonDecoder.decode(T.self, from: data)
    return (decodedData, response)
  }
  
  static func request<T: Decodable>(endpoint: Endpoint) throws -> AnyPublisher<(data: T, response: URLResponse), Error> {
    // iOS 13
    guard let url = URL(string: API.baseURLString + endpoint.path) else {
      throw APIError.invalidURL
    }
    let urlRequest = URLRequest(url: url)
    let publisher = URLSession.shared
      .dataTaskPublisher(for: urlRequest)
      .tryMap { result -> (data: T, response: URLResponse) in
        try? debugPrint(response: result.response, data: result.data)
        let decodedData = try API.jsonDecoder.decode(T.self, from: result.data)
        return (data: decodedData, response: result.response)
      }
      .receive(on: API.scheduler)
      .eraseToAnyPublisher()
    return publisher
  }
  
  static func request<T: Decodable>(endpoint: Endpoint, completion: @escaping (Result<(data: T, response: URLResponse), Error>) -> Void) throws {
    // iOS 7
    guard let url = URL(string: API.baseURLString + endpoint.path) else {
      throw APIError.invalidURL
    }
    let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
      switch error {
      case .some(let error):
        completion(.failure(error))
      default:
        guard let data = data, let response = response else {
          completion(.failure(APIError.requestError))
          return
        }
        do {
          let decodedData = try API.jsonDecoder.decode(T.self, from: data)
          completion(.success((data: decodedData, response: response)))
        } catch {
          completion(.failure(error))
        }
      }
    }
    
    dataTask.resume()
  }
  
  static func debugPrint(response: URLResponse, data: Data) throws {
    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: [])
    let responseFormat = "---------HTTP RESPONSE-------\n"
    let dataFormat = "--------DATA--------"
    print(responseFormat, response, dataFormat, jsonDictionary, separator: "\n", terminator: "-------------\n\n")
  }
}
