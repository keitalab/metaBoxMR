//
//  FleaMarketBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/11/09.
//

import SwiftUI

class ProductInfo: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var price: Int? = nil
    @Published var isSelling: Bool = false
}

struct FleaMarketBoxView: View {
    @StateObject private var productInfo = ProductInfo()
    
    @State private var currentView: Int = 0
    
    var body: some View {
        VStack {
            VStack {
                Picker("", selection: self.$currentView) {
                    Text("購入")
                        .tag(0)
                    Text("出品")
                        .tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .glassBackgroundEffect()
            }
            
            VStack {
                switch currentView {
                case 1:
                    saleView(productInfo: productInfo)
                        .transition(.blurReplace)
                default:
                    shopView(productInfo: productInfo)
                        .transition(.blurReplace)
                }
            }
            .frame(width: 400, height: 400)
        }
        .background(Color.clear)
        .animation(.default, value: currentView)
        
//        TabView {
//            saleView(productInfo: productInfo)
//                .tabItem {
//                    Label("出品", systemImage: "camera.fill")
//                }.tag(0)
//
//            shopView(productInfo: productInfo)
//                .tabItem {
//                    Label("購入", systemImage: "cart.fill")
//                }.tag(1)
//        }
    }
   
    struct FleaMarketBoxView_Previews: PreviewProvider {
        static var previews: some View {
            FleaMarketBoxView()
        }
    }
}

// 出品ビュー
struct saleView: View {
    @ObservedObject var productInfo: ProductInfo
    
    @State private var currentView: Int = 0
    
    @State private var isShowAlert: Bool = false

    @State private var _name: String = ""
    @State private var _description: String = ""
    @State private var _price: Int? = nil
    
    // 商品情報を登録
    func setInfo() {
        productInfo.name = _name
        productInfo.description = _description
        productInfo.price = _price
        productInfo.isSelling = true
    }
    
    // body
    var body: some View {
        ZStack {
            switch currentView {
            case 1:
                attentionView
                    .transition(.blurReplace)
            case 2:
                sucsessView
                    .transition(.blurReplace)
            default:
                if(!productInfo.isSelling) {
                    infoView
                        .transition(.blurReplace)
                } else {
                    cannotSaleView
                        .transition(.blurReplace)
                }
            }
        }
        .background(Color.clear)
        .animation(.default, value: currentView)
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
                    TextField("商品名を入力してください", text: $_name)
                }
                
                VStack(alignment: .leading) {
                    Text("商品の説明")
                        .font(.title2)
                    TextField("商品の説明を入力してください", text: $_description)
                }

                VStack(alignment: .leading) {
                    Text("金額")
                        .font(.title2)
                    TextField("商品の金額を入力してください", value: $_price, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Button("次に進む") {
                if _name == "" || _description == "" || _price == nil {
                    isShowAlert = true
                }
                
                if(!isShowAlert) {
                    currentView = 1
                    
                    // metaBoxを解錠
                    unlock()
                }
            }
            .alert("必要な情報が入力されていません", isPresented: $isShowAlert) {
                Button("入力する") {}
            } message: {
                if _name == "" {
                    Text("商品名を入力してください")
                } else if _description == "" {
                    Text("商品の説明を入力してください")
                } else if _price == nil {
                    Text("金額を入力してください")
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
                    currentView = 0
                }
                
                Button("商品を出品する") {
                    currentView = 2

                    // 商品情報を登録
                    setInfo()
                }
            }
        }
    }
    
    // 出品完了
    var sucsessView: some View {
        VStack {
            Text("出品が完了しました")
                .padding()
                .font(.title)
            
            Button("トップページに戻る") {
                currentView = 0
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
struct shopView: View {
    @ObservedObject var productInfo: ProductInfo
    
    @State private var currentView: Int = 0
    
    func initInfo() {
        productInfo.name = ""
        productInfo.description = ""
        productInfo.price = nil
        productInfo.isSelling = false
    }
    
    var body: some View {
        ZStack {
            switch currentView {
            case 1:
                completeView
                    .transition(.blurReplace)
            default:
                if(!productInfo.isSelling) {
                    cannotshopView
                        .transition(.blurReplace)
                } else {
                    mainView
                        .transition(.blurReplace)
                }
            }
        }
        .background(Color.clear)
        .animation(.default, value: currentView)
    }
    
    // 販売中の商品情報
    var mainView: some View {
        VStack {
            Text("フリマBox")
                .padding()
                .font(.title)
            
            Spacer()
            
            VStack(spacing: 10) {
                HStack {
                    Text(productInfo.name)
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
                        Text(String(productInfo.price ?? 0))
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
                    Text(String(productInfo.description))
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button("購入する") {
                currentView = 1
                
                // 商品情報を初期化
                initInfo()
                
                // metaBoxを解錠
                unlock()
            }
            .padding()
        }
        .frame(width: 400, height: 400)
    }
    
    // 購入完了画面
    var completeView: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
                Text("購入が完了しました")
                    .font(.system(size: 20, weight: .semibold))
            }
                
            HStack {
                Text(productInfo.name)
                    .font(.system(size: 24, weight: .semibold))
            }
            
            Button("購入画面に戻る") {
                currentView = 0
            }
            .padding()
        }
    }
    
    // 出品されていない場合
    var cannotshopView: some View {
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
