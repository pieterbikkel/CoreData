//
//  PersistenceCoordinatorTests.swift
//  PersistenceCoordinatorTests
//
//  Created by Pieter Bikkel on 05/09/2020.
//  Copyright © 2020 Pieter Bikkel. All rights reserved.
//

import XCTest
import CoreData

class PersistenceCoordinatorTests: XCTestCase {
    
    var managedObjectModel: NSManagedObjectModel!
    var coordinator: PersistenceCoordinator!

    override func setUpWithError() throws {
        
        let bundle = Bundle(for: PersistenceCoordinatorTests.self)
        
        guard let url = bundle.url(forResource: "CoreDataTut", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: url)
        else {
            XCTFail("Failed to load the test dependency")
            return
        }
        
        managedObjectModel = model
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        coordinator = PersistenceCoordinator(model: managedObjectModel, storeDescription: description)
        XCTAssertNotNil(coordinator)
        
        let construcExpectation = self.expectation(description: "Construct Expectation")
        
        coordinator.constructCoreDataStack { constructError in
            XCTAssert((constructError != nil))
            construcExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    //naming a test: test_methodName_withCertainState_ShouldDoSomething
    
    func testInitializer_providedManagedObjectModelAndStoreDescription_coordinatesInitializedSuccesfully() {
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        let persistenceCoordinator = PersistenceCoordinator(model: managedObjectModel, storeDescription: description)
        
        XCTAssert(persistenceCoordinator.model === managedObjectModel)
        XCTAssert(persistenceCoordinator.persistentContainer.name.isEmpty)
        XCTAssert(persistenceCoordinator.persistentContainer.managedObjectModel === managedObjectModel)
        XCTAssert(persistenceCoordinator.persistentContainer.persistentStoreDescriptions.first === description)
    }
    
    func testInitializer_providedPersistentContainer_coordinatesInitializedSuccesfully() {
        
        let persistentContainer = NSPersistentContainer(name: "", managedObjectModel: managedObjectModel)
        let persistentCoordinator = PersistenceCoordinator(persistentContainer: persistentContainer)
        
        XCTAssertNotNil(persistentCoordinator.persistentContainer)
        XCTAssert(persistentCoordinator.persistentContainer.managedObjectModel === managedObjectModel)
        XCTAssert(persistentCoordinator.model === managedObjectModel)
    }
    
    func testConstructCoreDataStack_completionHandlerCalledSucces() {
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        let persistenceCoordinator = PersistenceCoordinator(model: managedObjectModel, storeDescription: description)
        
        let setupExpectation = self.expectation(description: "Construct Stack Expectation")
        
        persistenceCoordinator.constructCoreDataStack { error in
            
            XCTAssertNil(error)
            
            XCTAssert(persistenceCoordinator.persistentContainer.persistentStoreDescriptions.count == 1)
            XCTAssert(persistenceCoordinator.persistentContainer.persistentStoreDescriptions.first === description)
            XCTAssert(persistenceCoordinator.persistentContainer.persistentStoreDescriptions.first?.type == NSInMemoryStoreType)
            
            setupExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
        
    }
    
    func testSaveChanges_inPrivateContext_completionHandlerCalledSucces() {
        
        let expectedFolderTitle = "Test Folder Title"
        let expectedFolderCreatedDate = Date()
        
        let expectedNoteTitle = "Test Note Title"
        let expectedNoteMessage = "Test Note Message"
        let expectedNoteDate = Date()
        
        let savingContext = coordinator.privateContext
        
        let folder = Folder(context: savingContext)
        folder.title = expectedFolderTitle
        folder.createdDate = expectedFolderCreatedDate
        
        let note = Note(context: savingContext)
        note.title = expectedNoteTitle
        note.fullNote = expectedNoteMessage
        note.createdDate = expectedNoteDate
        
        folder.addToNotes(note)
        
        let saveExpectation = self.expectation(description: "Save Expectation")
        
        coordinator.saveChanges(in: savingContext) { saveError in
            XCTAssertNil(saveError)
            XCTAssertFalse(Thead.current.isMainThread)
            
            self.coordinator.fetch(from: savingContext, fetchRequest: Folder.fetchRequest(), fetchCompletionHandler: {
                    (fetchedResults, fetchError) in
                
                XCTAssertNotNil(fetchedResults)
                XCTAssertNil(fetchError)
                XCTAssert(fetchedResults?.count == 1)
                XCTAssert(fetchedResults is [Folder])
                
                let folders = fetchedResults as? [Folder]
                let folder = folders?.first
                
                XCTAssertNotNil(folder)
                XCTAssertEqual(folder?.title, expectedFolderTitle)
                XCTAssertEqual(folder?.createdDate, expectedFolderCreatedDate)
                XCTAssert(folder.notes?.count == 1)
                XCTAssert(folder?.managedObjectContext === savingContext)
                
                
                if let notes = folder?.notes?.allObjects as? [Note] {
                    
                    for note in notes {
                        XCTAssertEqual(note.title, expectedNoteTitle)
                            XCTAssertEqual(note.fullNote, expectedNoteMessage)
                            XCTAssertEqual(note.createdDate, expectedNoteDate)
                        XCTAssertNotNil(note.folder)
                        XCTAssert(note.folder === folder)
                        XCTAssert(note.managedObjectContext === savingContext)
                    }
                }
                
                saveExpectation.fulfill()
                
            })
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
        
        
    }

}
