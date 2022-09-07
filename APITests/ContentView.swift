//
//  ContentView.swift
//  APITests
//
//  Created by Bruce Rick on 2022-08-30.
//

import SwiftUI
import Combine

struct ContentView: View {
  @State var pokedex: Pokedex?
  @State private var cancellable: AnyCancellable?
  
  var body: some View {
    List(pokedex?.pokemonEntries ?? [], id: \.entryNumber) {
      Text($0.pokemonSpecies.name)
    }
    .onAppear {
      if #available(iOS 15, *) {
        print("iOS 15 available. Using Await method")
        getPokedexByAwait()
      }
      else if #available(iOS 13, *) {
        print("iOS 13 available. Using publisher method")
        getPokedexByPublisher()
      }
      else {
        print("iOS 7 available. Using publisher method")
        getPokedexByDataTask()
      }
    }
  }
  
  func getPokedexByAwait() {
    Task {
      do {
        pokedex = try await API.request(endpoint: .pokedex("2")).data
      } catch {
        print(error)
      }
    }
    
  }
  
  func getPokedexByPublisher() {
    do {
      cancellable = try API.request(endpoint: .pokedex("2"))
        .map(\.data)
        .replaceError(with: nil)
        .assign(to: \.pokedex, on: self)
    } catch {
      print(error)
    }
  }
  
  func getPokedexByDataTask() {
    do {
      try API.request(endpoint: .pokedex("2")) { (result: Result<(data: Pokedex, response: URLResponse), Error>) in
        switch result {
        case .success(let (data, _)):
          pokedex = data
        case .failure(let error):
          print(error)
        }
      }
    } catch {
      print(error)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
