//
//  FleaMarketBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/11/09.
//

import SwiftUI

final class FleaMarketBox: AppClass {
    static let shared = FleaMarketBox()
}

// 商品情報の型定義
struct Product {
    var name: String
    var description: String
    var price: Int
}

// 商品情報
class ProductViewModel: ObservableObject {
    @Published var product: Product?
    
    func initProduct() {
        product = nil
    }
    
    func setProduct(product: Product) {
        self.product = product
    }
}

struct FleaMarketBoxView: View {
    // 状態遷移
    enum ViewState {
        case sale, shop
    }
    
    @StateObject private var productViewModel = ProductViewModel()
    
    @State private var currentState: ViewState = .shop
    
    var body: some View {
        VStack {
            VStack {
                Picker("", selection: self.$currentState) {
                    Text("購入")
                        .tag(ViewState.shop)
                    Text("出品")
                        .tag(ViewState.sale)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .glassBackgroundEffect()
            }
            
            VStack {
                switch currentState {
                case .sale:
                    SaleView(productViewModel: productViewModel)
                        .transition(.blurReplace)
                case .shop:
                    ShopView(productViewModel: productViewModel)
                        .transition(.blurReplace)
                }
            }
            .frame(width: 400, height: 400)
        }
        .background(Color.clear)
        .animation(.default, value: currentState)
    }
   
    struct FleaMarketBoxView_Previews: PreviewProvider {
        static var previews: some View {
            FleaMarketBoxView()
        }
    }
}

// 出品ビュー
struct SaleView: View {
    // 状態遷移
    enum ViewState {
        case attention, success, info
    }
    
    @ObservedObject var productViewModel: ProductViewModel
    @State private var currentState: ViewState = .info
    @State private var isShowAlert: Bool = false
    @State private var formInfo: Product = Product(name: "", description: "", price: 0)
    
    // 商品情報を登録
    func setInfo() {
        productViewModel.product = formInfo
    }
    
    // body
    var body: some View {
        ZStack {
            switch currentState {
            case .attention:
                attentionView
                    .transition(.blurReplace)
            case .success:
                successView
                    .transition(.blurReplace)
            case .info:
                if(productViewModel.product == nil) {
                    infoView
                        .transition(.blurReplace)
                } else {
                    cannotSaleView
                        .transition(.blurReplace)
                }
            }
        }
        .background(Color.clear)
        .animation(.default, value: currentState)
    }
    
    // 商品情報入力
    var infoView: some View {
        VStack {
            Text("商品情報を入力")
                .padding()
                .font(.title)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading) {
                    Text("商品名")
                        .font(.title2)
                    TextField("商品名を入力してください", text: $formInfo.name)
                }
                
                VStack(alignment: .leading) {
                    Text("商品の説明")
                        .font(.title2)
                    TextField("商品の説明を入力してください", text: $formInfo.description)
                }

                VStack(alignment: .leading) {
                    Text("金額")
                        .font(.title2)
                    TextField("商品の金額を入力してください", value: $formInfo.price, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Button("次に進む") {
                guard !formInfo.name.isEmpty,
                      formInfo.price > 0 else {
                    isShowAlert = true
                    return
                }
                
                currentState = .attention
                unlock()
            }
            .alert("必要な情報が入力されていません", isPresented: $isShowAlert) {
                Button("入力する") {}
            } message: {
                if formInfo.name.isEmpty {
                    Text("商品名を入力してください")
                } else if formInfo.price <= 0 {
                    Text("金額を入力してください")
                } else {
                    Text("入力内容に不備があります")
                }
            }
            .padding()
        }
        .frame(width: 400, height: 400)
    }
    
    // 確認
    var attentionView: some View {
        VStack {
            Text("出品する商品をBoxに\n入れてください")
                .font(.title)
                .padding()
                .multilineTextAlignment(.center)
                .lineSpacing(10)
            
            HStack(spacing: 20) {
                Button("戻る") {
                    currentState = .info
                }
                
                Button("商品を出品する") {
                    currentState = .success

                    // 商品情報を登録
                    productViewModel.setProduct(product: formInfo)
                }
            }
        }
    }
    
    // 出品完了
    var successView: some View {
        VStack {
            Text("出品が完了しました")
                .padding()
                .font(.title)
            
            Button("トップページに戻る") {
                currentState = .info
            }
        }
    }
    
    // 出品ができない場合
    var cannotSaleView: some View {
        VStack {
            Text("商品が出品できません")
                .padding()
                .font(.title)
            
            Text("このBoxで他の商品が出品されているため\n商品を出品できません。")
                .padding()
                .multilineTextAlignment(.center)
                .lineSpacing(10)
        }
    }
}

// 販売ビュー
struct ShopView: View {
    // 状態遷移
    enum ViewState {
        case main, complete
    }
    
    @ObservedObject var productViewModel: ProductViewModel
    @State private var currentState: ViewState = .main
    
    var body: some View {
        ZStack {
            switch currentState {
            case .complete:
                completeView
                    .transition(.blurReplace)
            case .main:
                if(productViewModel.product == nil) {
                    cannotShopView
                        .transition(.blurReplace)
                } else {
                    mainView
                        .transition(.blurReplace)
                }
            }
        }
        .background(Color.clear)
        .animation(.default, value: currentState)
    }
    
    // 販売中の商品情報
    var mainView: some View {
        VStack {
            if let product = productViewModel.product {
                Text("フリマBox")
                    .padding()
                    .font(.title)
                
                Spacer()
            
                VStack(spacing: 10) {
                    HStack {
                        Text(product.name)
                            .font(.system(size: 24, weight: .semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    
                    HStack {
                        HStack(alignment: .bottom, spacing: 0) {
                            Text("￥")
                                .baselineOffset(5)
                                .font(.system(size: 20))
                                .foregroundStyle(.tertiary)
                            Text((product.price == 0) ? "無料" : String(product.price))
                                .font(.system(size: 36, weight: .semibold))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 37)
                    
                    HStack {
                        Text(String("商品の説明"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 40)
                    
                    HStack {
                        Text((product.description.isEmpty) ? "商品の説明はありません" : product.description)
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button("購入する") {
                    currentState = .complete
                    
                    // metaBoxを解錠
                    unlock()
                }
                .padding()
            } else {
                
            }
        }
        .frame(width: 400, height: 400)
    }
    
    // 購入完了画面
    var completeView: some View {
        VStack(spacing: 10) {
            if let product = productViewModel.product {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text("購入が完了しました")
                        .font(.system(size: 20, weight: .semibold))
                }
                    
                HStack {
                    Text(product.name)
                        .font(.system(size: 24, weight: .semibold))
                }
                
                Button("購入画面に戻る") {
                    productViewModel.initProduct()
                    currentState = .main
                }
                .padding()
            }
        }
    }
    
    // 出品されていない場合
    var cannotShopView: some View {
        VStack {
            Text("商品が出品されていません")
                .padding()
                .font(.title)
            
            Text("このBoxで商品が出品されていないため\n商品を購入できません。")
                .padding()
                .multilineTextAlignment(.center)
                .lineSpacing(10)
        }
    }
}

#Preview(windowStyle: .automatic) {
    FleaMarketBoxView()
}
