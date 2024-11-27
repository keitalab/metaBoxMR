//
//  PayBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/28.
//

import SwiftUI

struct PayBoxView: View {
    @State private var productName = "商品名"
    @State private var productDescription = "商品の説明がここに記載されます"
    @State private var price: Int = 2980
    @State private var isPaid = false
    
    // メインビュー
    var body: some View {
        VStack {
            Text("Pay Box")
                .padding()
                .font(.title)
            if !isPaid {
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(productName)
                            .font(.system(size: 24, weight: .semibold))
                        
                        HStack(alignment: .bottom, spacing: 0) {
                            Text("￥")
                                .baselineOffset(5)
                                .font(.system(size: 20))
                                .foregroundStyle(.tertiary)
                            Text(String(price))
                                .font(.system(size: 36, weight: .semibold))
                        }
                        
                        Text(String("商品の説明"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 30)
                        
                        Text(String(productDescription))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Button("購入する") {
                        isPaid = true
                    }
                    .padding()
                }
                .frame(width: 400, height: 300)
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.green)
                        Text("購入が完了しました")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    Spacer()
                        
                    HStack {
                        Text(productName)
                            .font(.system(size: 24, weight: .semibold))
                    }
                    
                    HStack(alignment: .bottom, spacing: 0) {
                        Text("￥")
                            .baselineOffset(5)
                            .font(.system(size: 20))
                            .foregroundStyle(.tertiary)
                        Text(String(price))
                            .font(.system(size: 36, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    Button("購入画面に戻る") {
                        isPaid = false
                    }
                    .padding()
                }
                .frame(width: 400, height: 300)
            }
        }
        .frame(width: 400, height: 400)
        .background(Color.clear)
    }
    
    struct PayBoxView_Previews: PreviewProvider {
        static var previews: some View {
            PayBoxView()
        }
    }
}

#Preview(windowStyle: .automatic) {
    PayBoxView()
}
