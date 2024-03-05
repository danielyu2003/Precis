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
		// TODO: Replace with OpenAI API
		struct DefinitionBody: Codable {
			let definition: String
		}
		let word: String
		let results: [DefinitionBody]
	}
	
	enum Length: EnumerableFlag {
		case short
		case medium
		case long
	}
	
	enum PrecisError: Error {
		case missingAPIKey
		case nilResponse
		case errStatusCode(Int)
	}
	
	@Argument(help: "The sent prompt.")
	var query: String
	
	@Option(help: "The OpenAI API key.")
	var api_key: String?
	
	@Flag(exclusivity: .exclusive, help: "The response length.")
	var outputLength: Length = .short
	
	mutating func run() async throws {
		api_key = api_key ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
		guard let api_key = api_key else { throw PrecisError.missingAPIKey }
		print("generating \(outputLength) summary of \(query)...")
		try await submitQuery(api_key)
	}
	
	func submitQuery(_ api_key: String) async throws {
		// TODO: replace with OpenAI API
		let base = URL(string: "https://wordsapiv1.p.rapidapi.com/words/")!
		let url = URL(string: query, relativeTo: base)!
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.addValue(api_key, forHTTPHeaderField: "X-Mashape-Key")
		
		let (data, response) = try await URLSession.shared.data(for: request)
		guard let response = response as? HTTPURLResponse else {
			throw PrecisError.nilResponse
		}
		if response.statusCode < 200 || response.statusCode >= 300 {
			throw PrecisError.errStatusCode(response.statusCode)
		}
		let responseBody = try JSONDecoder().decode(ResponseBody.self, from: data)
		
		// TODO: replace with OpenAI ResponseBody
		let body = responseBody.results.first ?? ResponseBody.DefinitionBody(definition: "No definition found")
		print(body.definition)
	}
}
