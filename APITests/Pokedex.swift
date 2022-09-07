//
//  Pokedex.swift
//  APITests
//
//  Created by Charlie Rick on 2022-08-30.
//

import Foundation

struct Pokedex: Decodable {
  var name: String
  var id: Int
  var pokemonEntries: [Pokemon]

  struct Pokemon: Decodable {
    var entryNumber: Int
    var pokemonSpecies: Species
  }
  
  struct Species: Decodable {
    var name: String
  }
}
