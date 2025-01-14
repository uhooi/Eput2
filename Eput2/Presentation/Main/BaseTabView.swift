//
//  BaseTabView.swift
//  Eput2
//
//  Created by 土井星太朗 on 2024/03/30.
//

import SwiftUI

struct BaseTabView: View {
    @State var selection: TagModel
    @State var tagItem: [TagModel] = []
    @State var showInputModal = false
    @State var wordList = [WordModel]()
    @State var checkedItems: Set<WordModel> = []
    private let wordAppService: WordAppService = DefaultWordAppService()

    init() {
        let items = wordAppService.getAllTags()
        _tagItem = State(initialValue: items)
        _selection = State(initialValue: items.isEmpty ? TagModel(id: "dummy",
                                                                  tagName: "hello, swift") : items[0])
        items.forEach { item in
            let words = wordAppService.getWords(of: item.id)
            let previousWords = wordAppService.getWordsFromUserDefaults(item.id)
            if Set(previousWords) != Set(words) {
                wordAppService.saveWordsToUserDefaults(words.map { $0.toDTO() },
                                                       for: selection.id)
            }
        }

        let words = wordAppService.getWords(of: selection.id)
        let previousWords = wordAppService.getWordsFromUserDefaults(selection.id)
        if Set(previousWords) != Set(words) {
            _wordList = State(initialValue: words)
        } else {
            _wordList = State(initialValue: previousWords)
        }
    }

    var body: some View {
            NavigationView {
                TabView(selection: $selection) {
                    if tagItem.isEmpty && wordList.isEmpty {
                        VStack {
                            Image("empty-list")
                                .resizable()
                                .frame(width: 200, height: 200)
                                .aspectRatio(contentMode: .fit)
                                .overlay(Color.white.opacity(0.5))
                                .padding()
                            Text("まだワードが登録されていません")
                                .font(.system(size: 20))
                                .overlay(Color.white.opacity(0.5))
                                .padding()
                            Text("右上の+ボタンから追加してください")
                                .overlay(Color.white.opacity(0.5))
                                .font(.system(size: 15))
                        }
                    } else {
                        ForEach(tagItem, id: \.self) { tag in
                            WordListView(deleteWord: { word in
                                deleteWord(word)
                            },
                                         checkedItems: $checkedItems,
                                         itemList: $wordList,
                                         onOrderChange: { newOrderList in
                                wordAppService.saveWordsToUserDefaults(newOrderList.map { $0.toDTO() },
                                                                       for: selection.id)
                            },
                                         selectedTag: selection)
                            .tabItem {
                                Label(tag.tagName,
                                      systemImage: "tag")
                            }
                            .tag(tag)
                        }
                    }
                }
                .onChange(of: selection) { _, _ in
                    let newWords = wordAppService.getWords(of: selection.id)
                    let previousWords = wordAppService.getWordsFromUserDefaults(selection.id)
                    if Set(previousWords) != Set(newWords) {
                        wordList = newWords
                    } else {
                        wordList = previousWords
                    }
                }
                .fullScreenCover(isPresented: $showInputModal) {
                    InputModal(tags: $tagItem,
                               onDismiss: { tag, word in
                        var previousWords = wordAppService.getWordsFromUserDefaults(tag.id)
                        previousWords.append(word)
                        wordAppService.saveWordsToUserDefaults(previousWords.map { $0.toDTO() },
                                                               for: tag.id)
                        if tag.id == selection.id {
                            wordList = previousWords
                        } else {
                            wordList = wordAppService.getWordsFromUserDefaults(selection.id)
                        }
                        tagItem = wordAppService.getAllTags()
                    },
                               onRegisterTag: {
                        tagItem = wordAppService.getAllTags()
                        selection = tagItem[0]
                    })
                }
                .toolbar {
                    Button("+") {
                        showInputModal.toggle()
                    }
                    .font(.title3)
                    .padding()
                }
            }
    }

    func deleteWord(_ word: WordModel) {
        Task {
            try wordAppService.deleteWord(word.toDTO())
            wordList.removeAll(where: { $0 == word })
            wordAppService.saveWordsToUserDefaults(wordList.map { $0.toDTO() },
                                                   for: selection.id)
            checkedItems.remove(word)
        }
    }
}

#Preview {
    BaseTabView()
}
