//
//  PayBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/28.
//

import SwiftUI

struct PayBoxView: View {
    @State private var productName = "商品名"
    @State private var productDescription = "商品の説明がここに記載されます。"
    @State private var price: Int = 2980
    
    // メインビュー
    var body: some View {
        VStack {
            Text("Pay Box")
                .padding()
                .font(.title)
            VStack {
                Spacer()
                
                VStack(spacing: 10) {
                    HStack {
                        Text(productName)
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
                            Text(String(price))
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
                        Text(String(productDescription))
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
                Spacer()
                Button("購入する") {
                }
                .padding()
            }
            .frame(width: 400, height: 300)
        }
        .frame(width: 400, height: 400)
        .background(Color.black.opacity(0))
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
