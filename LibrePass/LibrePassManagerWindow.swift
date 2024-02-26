//
//  LibrePassManagerWindow.swift
//  LibrePass
//
//  Created by Zapomnij on 18/02/2024.
//

import SwiftUI

struct LibrePassManagerWindow: View {
    @State private var errorString: String = " "
    @State private var showAlert = false
    @State private var new = false
    @State private var logOut = false
    
    @Binding var lClient: LibrePassClient
    
    @Binding var loggedIn: Bool
    @Binding var locallyLoggedIn: Bool
    
    @State var refreshIndicator: Bool = false
    @State var deletionIndicator: Bool = false
    
    @State var toDelete: IndexSet = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.lClient.vault.vault, id: \.self.id) { cipher in
                    let index = lClient.vault.vault.firstIndex(where: { vaultCipher in vaultCipher.id == cipher.id })!
                    
                    NavigationLink(destination: CipherView(lClient: $lClient, cipher: cipher, index: index)) {
                        HStack {
                            CipherButton(cipher: cipher)
                            
                            Spacer()
                        }
                    }
                }
                .onDelete { indexSet in
                    self.toDelete = indexSet
                    self.deletionIndicator = true
                }
            }
        
            .navigationTitle("Vault")
            .toolbar {
                HStack {
                    SpinningWheel(isPresented: self.$deletionIndicator, task: self.deleteCiphers)
                    SpinningWheel(isPresented: self.$refreshIndicator, task: self.syncVault)
                    
                    if !self.refreshIndicator && !self.deletionIndicator {
                        Button(action: {
                            self.logOut.toggle()
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundStyle(Color.red)
                            
                        }
                        Button(action: {
                            self.refreshIndicator = true
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            self.new.toggle()
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                while !self.loggedIn {
                    
                }
                
                self.refreshIndicator = true
            }
        }
        
        .alert(self.errorString, isPresented: self.$showAlert) {
            Button("OK", role: .cancel) {
                lClient.unAuth()
                self.loggedIn = false
            }
        }
        
        .alert("Select cipher type", isPresented: self.$new) {
            Button("Login data") {
                self.newCipher(type: .Login)
            }
            
            Button("Secure note") {
                self.newCipher(type: .SecureNote)
            }
            
            Button("Card data") {
                self.newCipher(type: .Card)
            }
            
            Button("Cancel", role: .cancel) {}
        }
        
        .alert("Are you sure you to log out?", isPresented: self.$logOut) {
            Button("Yes", role: .destructive) {
                self.lClient.logOut()
                
                self.locallyLoggedIn = false
                self.loggedIn = false
            }
            
            Button("No", role: .cancel) {}
        }
    }
    
    func syncVault() throws {
        try self.lClient.syncVault()
    }
    
    func deleteCiphers() throws {
        for index in self.toDelete {
            try self.lClient.delete(id: self.lClient.vault.vault[index].id)
        }
    }
    
    func newCipher(type: LibrePassCipher.CipherType) {
        let cipher = LibrePassCipher(id: lClient.generateId(), owner: lClient.credentialsDatabase!.userId, type: type)
        
        do {
            try self.lClient.put(cipher: cipher)
            try self.syncVault()
        } catch ApiClientErrors.StatusCodeNot200(let statusCode){
            self.errorString = String(statusCode)
            self.showAlert = true
        } catch {
            self.errorString = error.localizedDescription
            self.showAlert = true
        }
    }
}
