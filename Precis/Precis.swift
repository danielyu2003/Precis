//
//  Precis.swift
//  Precis
//
//  Created by Daniel Yu on 3/1/24.
//

import Foundation
import ArgumentParser

@main
struct Precis: AsyncParsableCommand {
	struct ResponseBody: Codable {
		let word: String
		let results: [DefinitionBody]
	}
	
	struct DefinitionBody: Codable {
		let definition: String
	}
	
	enum Length: EnumerableFlag {
		case Short
		case Medium
		case Long
	}
	
	enum PrecisError: Error {
		case missingAPIKey
		case invalidStatusCode
	}
	
	@Flag(exclusivity: .exclusive, help: "The relative size of the response.")
	var outputLength: Length = .Short
	
	@Argument(help: "The prompt of the query.")
	var query: String
	
	@Option(help: "The OpenAI API key.")
	var api_key: String?
	
	mutating func run() async throws {
		api_key = api_key ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
		guard let _ = api_key else { throw PrecisError.missingAPIKey }
		try await foo()
	}
	
	func foo() async throws {
		let base = URL(string: "https://wordsapiv1.p.rapidapi.com/words/")!
		let url = URL(string: query, relativeTo: base)!
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.addValue(api_key!, forHTTPHeaderField: "X-Mashape-Key")
		let (data, response) = try await URLSession.shared.data(for: request)
		guard let response = response as? HTTPURLResponse, (200..<300) ~= response.statusCode else {
			throw PrecisError.invalidStatusCode
		}
		let test = try JSONDecoder().decode(ResponseBody.self, from: data)
		print(test.results[0].definition)
	}
}
