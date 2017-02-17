@isTest
private class TestSightingTriggerHandler {

	/*
    * @scenario: setup test data and test bulk insert

			insert 500 Sighting records:

			Bald Eagle (records number: 50, total animal seen: 0,		status: approved, date: within past 12 months)
			Black Bear (records number: 50, total animal seen: 50,  status: approved, date: within past 12 months)
			Brown Bear (records number: 50, total animal seen: 200, status: approved, date: within past 12 months)
			Gyrfalcon	 (records number: 50, total animal seen: 500, status: approved, date: within past 12 months)

			Halibut		 (records number: 50, total animal seen: 0, 	status: not validated, date: within past 12 months)
			Orca			 (records number: 50, total animal seen: 50, 	status: not validated, date: within past 12 months)
			Polar Bear (records number: 50, total animal seen: 200,	status: not validated, date: within past 12 months)
			Salmon		 (records number: 50, total animal seen: 500, status: not validated, date: within past 12 months)

			Snowy Owl	 (records number: 50, total animal seen: 0,		status: rejected, date: within past 12 months)
			Trout		   (records number: 50, total animal seen: 500, status: approved, date: not within past 12 months)
  */
	@testSetup static void testSetup() {
		System.debug('***testSetup');
		List<Species__c> speciesList = TestUtils.createSpeciesListForInsert();
		insert speciesList;

		Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();

		List<Sighting__c> sightingList = new List<Sighting__c>();

		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 50, 0, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 50, 50, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 50, 200, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 50, 500, 'Approved', -6, null, null, null));

		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 50, 0, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 50, 50, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 50, 200, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 50, 500, 'Not Validated', -6, null, null, null));

		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Snowy Owl'), 50, 0, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 50, 500, 'Approved', -16, null, null, null));

		/* use Database.insert to allow partial success */
		Database.insert(sightingList, false);

		/* 450 records would be actually inserted since all 'Bald Eagle' records would fail due to Validataion Rule */
		List<AggregateResult> arList = [SELECT Count(Id) total FROM Sighting__c];
		System.assertEquals(arList[0].get('total'), 450);

		/*
			after bulk insert, the Rarity for each Species would be:

			Bald Eagle: Null
			Black Bear: Endangered
			Brown Bear: Rare
			Gyrfalcon: Common
			Halibut: Extinct
			Orca: Extinct
			Polar Bear: Extinct
			Salmon: Extinct
			Snowy Owl: Extinct
			Trout: Extinct
		*/
		List<Species__c> verifySpeciesList = [SELECT Name, Rarity__c FROM Species__c];
		for(Species__c species : verifySpeciesList){
			if(species.Name == 'Bald Eagle'){
				System.assertEquals(species.Rarity__c, null);
			}else if(species.Name == 'Black Bear'){
				System.assertEquals(species.Rarity__c, 'Endangered');
			}else if(species.Name == 'Brown Bear'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Gyrfalcon'){
				System.assertEquals(species.Rarity__c, 'Common');
			}else if(species.Name == 'Halibut'){
				System.assertEquals(species.Rarity__c, 'Extinct');
			}else if(species.Name == 'Orca'){
				System.assertEquals(species.Rarity__c, 'Extinct');
			}else if(species.Name == 'Polar Bear'){
				System.assertEquals(species.Rarity__c, 'Extinct');
			}else if(species.Name == 'Salmon'){
				System.assertEquals(species.Rarity__c, 'Extinct');
			}else if(species.Name == 'Snowy Owl'){
				System.assertEquals(species.Rarity__c, 'Extinct');
			}else if(species.Name == 'Trout'){
				System.assertEquals(species.Rarity__c, 'Extinct');
			}
		}
	}

	/*
    * @scenario: another bulk insert test with testSetup data available, and insert records of same Species in different batch

			insert total 600 Sighting records (60 Sighting records per Species, and were evenly split into the following 6 situations)

				1. status: approved, date: within past 12 months (250 animal seen per Species)
				2. status: rejected, date: within past 12 months (250 animal seen per Species)
				3. status: not validated: date: within past 12 months (250 animal seen per Species)
				4. status: approved, date: not within past 12 months (250 animal seen per Species)
				5. status: rejected, date: not within past 12 months (250 animal seen per Species)
				6. status: not validated, date: not within past 12 months (250 animal seen per Species)
  */
	@isTest static void bulk_insert_test() {
		System.debug('***bulk_insert_test');

		Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();

		List<Sighting__c> sightingList = new List<Sighting__c>();

		/* 1. status: approved, date: within past 12 months  */
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Snowy Owl'), 10, 250, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 10, 250, 'Approved', -6, null, null, null));

		/* 2. status: rejected, date: within past 12 months  */
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Snowy Owl'), 10, 250, 'Rejected', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 10, 250, 'Rejected', -6, null, null, null));

		/* 3. status: not validated: date: within past 12 months  */
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Snowy Owl'), 10, 250, 'Not Validated', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 10, 250, 'Not Validated', -6, null, null, null));

		/* 4. status: approved: date: not within past 12 months  */
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Snowy Owl'), 10, 250, 'Approved', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 10, 250, 'Approved', -16, null, null, null));

		/* 5. status: rejected: date: not within past 12 months  */
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Snowy Owl'), 10, 250, 'Rejected', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 10, 250, 'Rejected', -16, null, null, null));

		/* 6. status: not validated: date: not within past 12 months  */
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Snowy Owl'), 10, 250, 'Not Validated', -16, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 10, 250, 'Not Validated', -16, null, null, null));

		Test.startTest();
		/* use Database.insert to allow partial success */
		Database.insert(sightingList, false);
		Test.stopTest();

		/* all 600 records would be actually inserted, so the total Sighting records should be 450 + 600 = 1050  */
		List<AggregateResult> arList = [SELECT Count(Id) total FROM Sighting__c];
		System.assertEquals(arList[0].get('total'), 1050);

		/*
			after bulk insert, the Rarity for each Species would be:

			Bald Eagle: Rare
			Black Bear: Rare
			Brown Bear: Common
			Gyrfalcon: Common
			Halibut: Rare
			Orca: Rare
			Polar Bear: Rare
			Salmon: Rare
			Snowy Owl: Rare
			Trout: Rare
		*/
		List<Species__c> verifySpeciesList = [SELECT Name, Rarity__c FROM Species__c];
		for(Species__c species : verifySpeciesList){
			if(species.Name == 'Bald Eagle'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Black Bear'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Brown Bear'){
				System.assertEquals(species.Rarity__c, 'Common');
			}else if(species.Name == 'Gyrfalcon'){
				System.assertEquals(species.Rarity__c, 'Common');
			}else if(species.Name == 'Halibut'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Orca'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Polar Bear'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Salmon'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Snowy Owl'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Trout'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}
		}

	}

	/*
    * @scenario: update Sighting records with testSetup data available:

			initial status after testSetup:

			Bald Eagle (no records - failed to insert due to validation rule violation)
			Black Bear (records number: 50, total animal seen: 50,  status: approved, date: within past 12 months),
			Brown Bear (records number: 50, total animal seen: 200, status: approved, date: within past 12 months),
			Gyrfalcon	 (records number: 50, total animal seen: 500, status: approved, date: within past 12 months),

			Halibut		 (records number: 50, total animal seen: 0, 	status: not validated, date: within past 12 months),
			Orca			 (records number: 50, total animal seen: 50, 	status: not validated, date: within past 12 months),
			Polar Bear (records number: 50, total animal seen: 200,	status: not validated, date: within past 12 months),
			Salmon		 (records number: 50, total animal seen: 500, status: not validated, date: within past 12 months),

			Snowy Owl	 (records number: 50, total animal seen: 0,		status: rejected, date: within past 12 months),
			Trout		   (records number: 50, total animal seen: 500, status: approved, date: not within past 12 months)

			update to:

			Bald Eagle (records number: 50, total animal seen: 200,  status: approved, date: within past 12 months)
			Black Bear (records number: 50, total animal seen: 200,  status: approved, date: within past 12 months)
			Brown Bear (records number: 50, total animal seen: 200,  status: approved, date: within past 12 months)
			Gyrfalcon	 (records number: 50, total animal seen: 200,  status: approved, date: within past 12 months)

			Halibut		 (records number: 50, total animal seen: 0, 	status: approved, date: within past 12 months)
			Orca			 (records number: 50, total animal seen: 50, 	status: approved, date: within past 12 months)
			Polar Bear (records number: 50, total animal seen: 200,	status: approved, date: within past 12 months)
			Salmon		 (records number: 50, total animal seen: 500, status: approved, date: within past 12 months)

			Snowy Owl	 (records number: 50, total animal seen: 500,	status: approved, date: within past 12 months)
			Trout		   (records number: 50, total animal seen: 500, status: approved, date: within past 12 months)
  */
	@isTest static void bulk_update_test() {
		System.debug('***bulk_update_test');

		Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();

		List<Sighting__c> sightingList = new List<Sighting__c>();

		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 50, 200, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Black Bear'), 50, 200, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Brown Bear'), 50, 200, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Gyrfalcon'), 50, 200, 'Approved', -6, null, null, null));

		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Halibut'), 50, 0, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Orca'), 50, 50, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Polar Bear'), 50, 200, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Salmon'), 50, 500, 'Approved', -6, null, null, null));

		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Snowy Owl'), 50, 500, 'Approved', -6, null, null, null));
		sightingList.addAll(TestUtils.createSightingListForUpdate(speciesNameIdMap.get('Trout'), 50, 500, 'Approved', -6, null, null, null));

		Test.startTest();
		/* use Database.insert to allow partial success */
		Database.UpsertResult[] urList = Database.upsert(sightingList, false);
		Test.stopTest();

		/* all Halibut records would fail due to validataion rule violation */
		Integer failCount = 0;
		for(Database.UpsertResult ur : urList){
			if(!ur.isSuccess()){
				failCount++;
			}
		}
		System.assertEquals(failCount, 50);

		/*
			after bulk insert, the Rarity for each Species would be:

			Bald Eagle: Rare
			Black Bear: Rare
			Brown Bear: Common
			Gyrfalcon: Common
			Halibut: Rare
			Orca: Rare
			Polar Bear: Rare
			Salmon: Rare
			Snowy Owl: Rare
			Trout: Rare
		*/
		List<Species__c> verifySpeciesList = [SELECT Name, Rarity__c FROM Species__c];
		for(Species__c species : verifySpeciesList){
			if(species.Name == 'Bald Eagle'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Black Bear'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Brown Bear'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Gyrfalcon'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Halibut'){
				System.assertEquals(species.Rarity__c, 'Extinct');
			}else if(species.Name == 'Orca'){
				System.assertEquals(species.Rarity__c, 'Endangered');
			}else if(species.Name == 'Polar Bear'){
				System.assertEquals(species.Rarity__c, 'Rare');
			}else if(species.Name == 'Salmon'){
				System.assertEquals(species.Rarity__c, 'Common');
			}else if(species.Name == 'Snowy Owl'){
				System.assertEquals(species.Rarity__c, 'Common');
			}else if(species.Name == 'Trout'){
				System.assertEquals(species.Rarity__c, 'Common');
			}
		}
	}

}