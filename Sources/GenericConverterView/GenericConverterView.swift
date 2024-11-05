// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public struct ConverterViewModel {
    public var title: String
    public var subTitle: String
    public var itemsToConvert:[String]
    public var convertedResult:String
    
   public  init(title: String, subTitle: String, itemsToConvert: [String], convertedResult: String) {
        self.title = title
        self.subTitle = subTitle
        self.itemsToConvert = itemsToConvert
        self.convertedResult = convertedResult
    }
}

public protocol ConverterViewDataProvider:ObservableObject {
    func start(_ completion:((Bool)->())?)
    func convert(value:String?,amount:String)
    var convertItemModel:ConverterViewModel {get}
    var isLoading: Bool {get}
    var error: Error?{get set}
    var screenTitle: String{get set}
    var backGroundColour: Color {get set}
}

public struct ConverterView<T:ConverterViewDataProvider>: View where T: ObservableObject {
    @ObservedObject var presenter: T
    @State private var selection:String = ""
    @State private var amount = ""
    @FocusState private var amountIsFocused: Bool
    
    public var body: some View {
        if presenter.isLoading {
            ProgressView("fetching data")
        } else {
            VStack {
                Text(presenter.screenTitle).padding()
                VStack {
                    HStack {
                        VStack(alignment:.leading) {
                            CustomPicker(title: presenter.convertItemModel.title, selection: $selection, items: presenter.convertItemModel.itemsToConvert)
                                .frame(height: 100)
                                .cornerRadius(20)
                            HStack {
                                Text("\(presenter.convertItemModel.subTitle):")
                                    .foregroundColor(.black )
                                    .font(.subheadline)
                                TextField("", text: $amount)
                                    .focused($amountIsFocused)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .padding()
                        
                        Spacer()
                        Button("Convert") {
                            amountIsFocused = false
                            presenter.convert(value: selection, amount: amount)
                        }.background {
                            Color.secondary
                        }
                        .foregroundColor(.white)
                        .buttonStyle(.bordered)
                        .cornerRadius(10)
                    }.padding()
                }.errorAlert(error: $presenter.error)
                    .onAppear(perform: {
                        presenter.start(nil)
                    })
                    .background(presenter.backGroundColour)
                    .cornerRadius(10)
                
                Text("value: \(presenter.convertItemModel.convertedResult)")
            }
        }
    }
}


struct CustomPicker: View {
    public var title: String
    @Binding public var selection: String
    public var items: [String]
    
    public init(title: String, selection: Binding<String>, items: [String]) {
        self.title = title
        self._selection = selection
        self.items = items
    }
    
    var body: some View {
        VStack(alignment:.leading) {
            HStack(spacing:8) {
                Text("\(title) :")
                    .foregroundColor(.black )
                    .font(.subheadline)
                Picker(selection: $selection) {
                    ForEach(items,id: \.self) { item in
                                            HStack {
                                                Text("\(item)")
                                            }
                                        }
                } label: {
                    Text("")
                }
            }
            .padding(.vertical,9)
        }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        return alert(isPresented: .constant(localizedAlertError != nil), error: localizedAlertError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}
