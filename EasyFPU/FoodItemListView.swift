//
//  FoodItemListView.swift
//  EasyFPU
//
//  Created by Ulrich Rüth on 01.11.20.
//  Copyright © 2020 Ulrich Rüth. All rights reserved.
//

import SwiftUI

struct FoodItemListView: View {
    enum NotificationState {
        case successfullySavedFoodItem(String)
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    var category: FoodItemCategory
    @ObservedObject var composedFoodItem: ComposedFoodItemViewModel
    @ObservedObject var absorptionScheme: AbsorptionScheme
    var helpSheet: FoodItemListViewSheets.State
    var foodItemListTitle: String
    @Binding var showingMenu: Bool
    @Binding var selectedTab: Int
    @State private var searchString = ""
    @State private var showCancelButton: Bool = false
    @State private var showFavoritesOnly = false
    @State private var activeSheet: FoodItemListViewSheets.State?
    @State private var showingAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var notificationState: NotificationState?
    
    @FetchRequest(
        entity: FoodItem.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)
        ]
    ) var foodItems: FetchedResults<FoodItem>
    
    private var filteredFoodItems: [FoodItemViewModel] {
        if searchString == "" {
            return showFavoritesOnly ? foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.favorite && $0.category == self.category } : foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.category == self.category }
        } else {
            return showFavoritesOnly ? foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.favorite && $0.category == self.category && $0.name.lowercased().contains(searchString.lowercased()) } : foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.category == self.category && $0.name.lowercased().contains(searchString.lowercased()) }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                NavigationView {
                    VStack {
                        List {
                            // Search view
                            SearchView(searchString: self.$searchString, showCancelButton: self.$showCancelButton)
                                .padding(.horizontal)
                            ForEach(self.filteredFoodItems) { foodItem in
                                FoodItemView(composedFoodItem: composedFoodItem, foodItem: foodItem, category: self.category, selectedTab: $selectedTab)
                                    .environment(\.managedObjectContext, self.managedObjectContext)
                            }
                        }
                    }
                    .disabled(self.showingMenu ? true : false)
                    .navigationBarTitle(foodItemListTitle)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button(action: {
                                withAnimation {
                                    self.showingMenu.toggle()
                                }
                            }) {
                                Image(systemName: self.showingMenu ? "xmark" : "line.horizontal.3")
                                .imageScale(.large)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    self.activeSheet = helpSheet
                                }
                            }) {
                                Image(systemName: "questionmark.circle")
                                .imageScale(.large)
                                .padding()
                            }.disabled(self.showingMenu ? true : false)
                        }
                        
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button(action: {
                                withAnimation {
                                    self.showFavoritesOnly.toggle()
                                }
                            }) {
                                if self.showFavoritesOnly {
                                    Image(systemName: "star.fill")
                                    .foregroundColor(Color.yellow)
                                    .padding()
                                } else {
                                    Image(systemName: "star")
                                    .foregroundColor(Color.gray)
                                    .padding()
                                }
                            }.disabled(self.showingMenu ? true : false)
                            
                            Button(action: {
                                // Add new food item
                                activeSheet = .addFoodItem
                            }) {
                                Image(systemName: "plus.circle")
                                    .imageScale(.large)
                                    .foregroundColor(.green)
                            }.disabled(self.showingMenu ? true : false)
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .sheet(item: $activeSheet) {
                    sheetContent($0)
                }
                .alert(isPresented: self.$showingAlert) {
                    Alert(
                        title: Text("Notice"),
                        message: Text(self.errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                
                // The Bottom Sheet
                if !self.composedFoodItem.foodItems.isEmpty {
                    BottomSheetView(maxHeight: geometry.size.height * 0.95) {
                        bottomSheetContent()
                    }
                }
            }.edgesIgnoringSafeArea(.all)
            
            // Notification
            if notificationState != nil {
                NotificationView {
                    notificationViewContent()
                }
            }
        }
    }
    
    @ViewBuilder
    private func bottomSheetContent() -> some View {
        switch category {
        case .product:
            ComposedFoodItemEvaluationView(absorptionScheme: absorptionScheme, composedFoodItem: composedFoodItem)
        case .ingredient:
            FoodItemComposerView(composedFoodItem: composedFoodItem, notificationState: $notificationState)
        }
    }
    
    @ViewBuilder
    private func notificationViewContent() -> some View {
        switch notificationState {
        case .successfullySavedFoodItem(let name):
            HStack {
                Text("'\(name)' \(NSLocalizedString("successfully saved in Products", comment: ""))")
            }
            .onAppear() {
                Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { timer in
                    self.notificationState = nil
                }
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func sheetContent(_ state: FoodItemListViewSheets.State) -> some View {
        switch state {
        case .addFoodItem:
            FoodItemEditor(
                navigationBarTitle: NSLocalizedString("New \(category.rawValue)", comment: ""),
                draftFoodItem: // Create new empty draftFoodItem
                    FoodItemViewModel(
                        name: self.searchString,
                        category: category,
                        favorite: false,
                        caloriesPer100g: 0.0,
                        carbsPer100g: 0.0,
                        sugarsPer100g: 0.0,
                        amount: 0,
                        fatPer100g: 0.0,
                        proteinsPer100g: 0.0
                    ),
                category: category
            ).environment(\.managedObjectContext, managedObjectContext)
        case .productsListHelp:
            HelpView(helpScreen: .productsList)
        case .ingredientsListHelp:
            HelpView(helpScreen: .ingredientsList)
        }
    }
}
