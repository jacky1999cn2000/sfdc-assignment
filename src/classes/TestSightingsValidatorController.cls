@isTest
private class TestSightingsValidatorController {
	
	/*
    * @scenario: verify users with different profiles have correct access to certain Apex Class and VF Page
  */
	@isTest static void profile_access_test() {
		User dataValidator = TestUtils.createTestUser('dataValidator','Data Validator', null, null, null);
		User citizenVolunteer = TestUtils.createTestUser('citizenVolunteer','Citizen Scientist Volunteer', null, null, null);

		List<SetupEntityAccess> dataValidatorSEAList_ApexPage;
		List<SetupEntityAccess> dataValidatorSEAList_ApexClass;
		List<SetupEntityAccess> citizenVolunteerSEAList_ApexPage;
		List<SetupEntityAccess> citizenVolunteerSEAList_ApexClass;

		Test.startTest();

		System.runAs(dataValidator){
			dataValidatorSEAList_ApexPage = [SELECT Id FROM SetupEntityAccess WHERE Parent.Profile.Id = :UserInfo.getProfileId() AND SetupEntityId in (SELECT Id FROM ApexPage WHERE Name = 'SightingsValidatorPage' AND NamespacePrefix = null)];
			dataValidatorSEAList_ApexClass = [SELECT Id FROM SetupEntityAccess WHERE Parent.Profile.Id = :UserInfo.getProfileId() AND SetupEntityId in (SELECT Id FROM ApexClass WHERE Name = 'SightingsValidatorController' AND NamespacePrefix = null)];
		}

		System.runAs(citizenVolunteer){
			citizenVolunteerSEAList_ApexPage = [SELECT Id FROM SetupEntityAccess WHERE Parent.Profile.Id = :UserInfo.getProfileId() AND SetupEntityId in (SELECT Id FROM ApexPage WHERE Name = 'SightingsValidatorPage' AND NamespacePrefix = null)];
			citizenVolunteerSEAList_ApexClass = [SELECT Id FROM SetupEntityAccess WHERE Parent.Profile.Id = :UserInfo.getProfileId() AND SetupEntityId in (SELECT Id FROM ApexClass WHERE Name = 'SightingsValidatorController' AND NamespacePrefix = null)];
		}

		Test.stopTest();

		System.assertEquals(dataValidatorSEAList_ApexPage.size(), 1);
		System.assertEquals(dataValidatorSEAList_ApexClass.size(), 1);
		System.assertEquals(citizenVolunteerSEAList_ApexPage.size(), 0);
		System.assertEquals(citizenVolunteerSEAList_ApexClass.size(), 0);
	}

	/*
    * @scenario: verify "validUser" property works as expected
  */
	@isTest static void validUser_property_test() {
		/* creat a dataValidator user with "Data Validator" profile */
		User dataValidator = TestUtils.createTestUser('dataValidator','Data Validator', null, null, null);
		insert dataValidator;

		Test.startTest();

		/*
			run as dataValidator user (the user's Validation_Specialization__c field is null now)
			will generate ERROR ApexPages Message and assign "validUser" property to be false
		*/
		System.runAs(dataValidator){
			PageReference pageRef = Page.SightingsValidatorPage;
			Test.setCurrentPage(pageRef);
			SightingsValidatorController controller = new SightingsValidatorController();
			controller.getSightings();
			System.assertEquals(controller.validUser, false);
		}

		/* update user's Validation_Specialization__c field */
		dataValidator.Validation_Specialization__c = 'Birds';
		update dataValidator;

		/*
			run as dataValidator user (the user is not a member of any public groups)
			will generate INFO ApexPages Message and assign "validUser" property to be false
		*/
		System.runAs(dataValidator){
		  PageReference pageRef = Page.SightingsValidatorPage;
			Test.setCurrentPage(pageRef);
			SightingsValidatorController controller = new SightingsValidatorController();
			controller.getSightings();
			System.assertEquals(controller.validUser, false);
		}

		/* add user into a public group */
		List<Group> groupList = [SELECT Id FROM Group WHERE Type='Regular' AND Name='Bird Validators'];
		System.assertEquals(groupList.size(), 1);
		GroupMember gm = new GroupMember();
		gm.GroupId = groupList[0].Id;
		gm.UserOrGroupId = dataValidator.Id;
		insert gm;

		/*
			run as dataValidator user will assign "validUser" property to be true
		*/
		System.runAs(dataValidator){
		  PageReference pageRef = Page.SightingsValidatorPage;
			Test.setCurrentPage(pageRef);
			SightingsValidatorController controller = new SightingsValidatorController();
			controller.getSightings();
			System.assertEquals(controller.validUser, true);
		}

		Test.stopTest();

		/* verify ApexPages Messages */
		List<ApexPages.Message> messageList = ApexPages.getMessages();
		System.assertEquals(messageList.size(), 2);
		System.assertEquals(messageList[0].getSummary(), 'Current user has \'Data Validator\' profile but does not select a value for \'Validator Specialization\' field.');
		System.assertEquals(messageList[0].getSeverity(), ApexPages.Severity.ERROR);
		System.assertEquals(messageList[1].getSummary(), 'Current user has \'Data Validator\' profile but does not belong to any \'Validator Public Group\'.');
		System.assertEquals(messageList[1].getSeverity(), ApexPages.Severity.ERROR);
	}

	/*
    * @scenario: verify StandardSetController return correct data
		P.S. according to Salesforce documentation, criteria-based sharing rules can NOT be tested using Apex.
  */
	@isTest static void setController_test() {
		/*
			1. create a user with "Data Validator" as Profile, (60,160) as Default Sighting Location, and "Birds" as Specialization
			2. add this user into "Bird Validator" public group
			P.S. criteria-based sharing rules can NOT be tested using Apex, so step 2 was only to bypass validUser_property validation (see "validUser_property_test" method above)
		*/
		User dataValidator = TestUtils.createTestUser('dataValidator','Data Validator', 60, 160, 'Birds');
		insert dataValidator;
		List<Group> groupList = [SELECT Id FROM Group WHERE Type='Regular' AND Name='Bird Validators'];
		System.assertEquals(groupList.size(), 1);
		GroupMember gm = new GroupMember();
		gm.GroupId = groupList[0].Id;
		gm.UserOrGroupId = dataValidator.Id;
		insert gm;

		/*
			insert 54 Sighting records in 9 batches (with different Validation Status, Date, Species Name, Location)
			P.S. use "dataValidator" user to perform insert so that the user have visiblity for all these records
			(given OWD for Sighting is private and criteria-based sharing rules are not supported in Apex)
		*/
		System.runAs(dataValidator){
			List<Species__c> speciesList = TestUtils.createSpeciesListForInsert();
			insert speciesList;
			Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();
			List<Sighting__c> sightingList = new List<Sighting__c>();

			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 1, 10, 'Not Validated', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 1, 10, 'Not Validated', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 1, 10, 'Not Validated', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 1, 10, 'Not Validated', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 1, 10, 'Not Validated', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 1, 10, 'Not Validated', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 1, 10, 'Not Validated', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 1, 10, 'Not Validated', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 1, 10, 'Not Validated', -6, 60, 160, null));

			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 1, 10, 'Not Validated', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 1, 10, 'Not Validated', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 1, 10, 'Not Validated', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 1, 10, 'Not Validated', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 1, 10, 'Not Validated', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 1, 10, 'Not Validated', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 1, 10, 'Not Validated', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 1, 10, 'Not Validated', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 1, 10, 'Not Validated', -6, 60, -160, null));

			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 1, 10, 'Approved', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 1, 10, 'Approved', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 1, 10, 'Approved', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 1, 10, 'Approved', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 1, 10, 'Approved', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 1, 10, 'Approved', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 1, 10, 'Approved', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 1, 10, 'Approved', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 1, 10, 'Approved', -6, 60, 160, null));

			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 1, 10, 'Approved', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 1, 10, 'Approved', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 1, 10, 'Approved', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 1, 10, 'Approved', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 1, 10, 'Approved', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 1, 10, 'Approved', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 1, 10, 'Approved', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 1, 10, 'Approved', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 1, 10, 'Approved', -6, 60, -160, null));

			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 1, 10, 'Rejected', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 1, 10, 'Rejected', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 1, 10, 'Rejected', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 1, 10, 'Rejected', -4, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 1, 10, 'Rejected', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 1, 10, 'Rejected', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 1, 10, 'Rejected', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 1, 10, 'Rejected', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 1, 10, 'Rejected', -6, 60, 160, null));

			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 1, 10, 'Rejected', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 1, 10, 'Rejected', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 1, 10, 'Rejected', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Gyrfalcon'), 1, 10, 'Rejected', -4, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Halibut'), 1, 10, 'Rejected', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Orca'), 1, 10, 'Rejected', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Polar Bear'), 1, 10, 'Rejected', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Salmon'), 1, 10, 'Rejected', -6, 60, -160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Trout'), 1, 10, 'Rejected', -6, 60, -160, null));

			insert sightingList;
		}

		Test.startTest();

		List<Sighting__c> dataValidator_sightingList = new List<Sighting__c>();

		System.runAs(dataValidator){
			PageReference pageRef = Page.SightingsValidatorPage;
			Test.setCurrentPage(pageRef);
			SightingsValidatorController controller = new SightingsValidatorController();

			while(true){
				dataValidator_sightingList.addAll(controller.getSightings());
				if(!controller.setCon.getHasNext()){
					break;
				}else{
					controller.setCon.next();
				}
			}
		}

		Test.stopTest();

		System.assertEquals(dataValidator_sightingList.size(), 9);

		System.assertEquals(dataValidator_sightingList[0].Species__r.Name, 'Bald Eagle');
		System.assertEquals(dataValidator_sightingList[0].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[0].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[0].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[1].Species__r.Name, 'Halibut');
		System.assertEquals(dataValidator_sightingList[1].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[1].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[1].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[2].Species__r.Name, 'Orca');
		System.assertEquals(dataValidator_sightingList[2].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[2].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[2].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[3].Species__r.Name, 'Polar Bear');
		System.assertEquals(dataValidator_sightingList[3].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[3].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[3].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[4].Species__r.Name, 'Salmon');
		System.assertEquals(dataValidator_sightingList[4].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[4].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[4].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[5].Species__r.Name, 'Trout');
		System.assertEquals(dataValidator_sightingList[5].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[5].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[5].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[6].Species__r.Name, 'Black Bear');
		System.assertEquals(dataValidator_sightingList[6].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[6].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[6].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[7].Species__r.Name, 'Brown Bear');
		System.assertEquals(dataValidator_sightingList[7].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[7].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[7].Validation_Status__c, 'Not Validated');

		System.assertEquals(dataValidator_sightingList[8].Species__r.Name, 'Gyrfalcon');
		System.assertEquals(dataValidator_sightingList[8].Location__Latitude__s, 60);
		System.assertEquals(dataValidator_sightingList[8].Location__Longitude__s, 160);
		System.assertEquals(dataValidator_sightingList[8].Validation_Status__c, 'Not Validated');
	}

	/*
    * @scenario: test validate() method when "validateType" is "Reset"
	*/
	@isTest static void validate_reset_test() {
		PageReference pageRef = Page.SightingsValidatorPage;
		Test.setCurrentPage(pageRef);
		SightingsValidatorController controller = new SightingsValidatorController();
		controller.validateType = 'Reset';

		Test.startTest();
		controller.validate();
		Test.stopTest();

		List<ApexPages.Message> messageList = ApexPages.getMessages();
		System.assertEquals(messageList.size(), 0);
	}

	/*
    * @scenario: test validate() method when "sightingIds" is an empty string
	*/
	@isTest static void validate_sightingIds_isEmpty_test() {
		PageReference pageRef = Page.SightingsValidatorPage;
		Test.setCurrentPage(pageRef);
		SightingsValidatorController controller = new SightingsValidatorController();
		controller.validateType = 'Approve';
		controller.sightingIds = '';

		Test.startTest();
		controller.validate();
		Test.stopTest();

		List<ApexPages.Message> messageList = ApexPages.getMessages();
		System.assertEquals(messageList.size(), 1);
		System.assertEquals(messageList[0].getSummary(), 'You haven\'t selected any records.');
		System.assertEquals(messageList[0].getSeverity(), ApexPages.Severity.INFO);
	}

	/*
    * @scenario: test validate() method when approve with errors
	*/
	@isTest static void validate_approveWithErrors_test() {
		List<Species__c> speciesList = TestUtils.createSpeciesListForInsert();
		insert speciesList;
		Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();
		List<Sighting__c> sightingList = new List<Sighting__c>();

		/*
			insert 10 Sighting records with Number_of_Animals__c set to 0, and the other 10 with Number_of_Animals__c set to non-zero values
		*/
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 10, 'Not Validated', -6, 60, 160, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 0, 'Not Validated', -4, 60, 160, null));

		insert sightingList;

		PageReference pageRef = Page.SightingsValidatorPage;
		Test.setCurrentPage(pageRef);
		SightingsValidatorController controller = new SightingsValidatorController();
		controller.validateType = 'Approve';
		/* get comma separated sightingIds */
		List<String> sightingIdList = new List<String>();
		for(Sighting__c sighting : sightingList){
			sightingIdList.add(sighting.Id);
		}
		controller.sightingIds = String.join(sightingIdList, ',');

		Test.startTest();
		controller.validate();
		Test.stopTest();

		List<Sighting__c> verifyList1 = [SELECT Id FROM Sighting__c WHERE Validation_Status__c = 'Approved'];
		System.assertEquals(verifyList1.size(), 10);
		List<Sighting__c> verifyList2 = [SELECT Id FROM Sighting__c WHERE Validation_Status__c = 'Not Validated'];
		System.assertEquals(verifyList2.size(), 10);

		List<ApexPages.Message> messageList = ApexPages.getMessages();
		System.assertEquals(messageList.size(), 1);
		System.assertEquals(messageList[0].getSummary(), 'Some of the records did not save.Number of Animals must be greater than 0 in order to approve a Sighting.Please try again.');
		System.assertEquals(messageList[0].getSeverity(), ApexPages.Severity.ERROR);
	}

	/*
    * @scenario: test validate() method when approve without errors
	*/
	@isTest static void validate_approveWithoutErrors_test() {
		List<Species__c> speciesList = TestUtils.createSpeciesListForInsert();
		insert speciesList;
		Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();
		List<Sighting__c> sightingList = new List<Sighting__c>();

		/*
			insert 20 Sighting records with Number_of_Animals__c set to non-zero values
		*/
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 20, 20, 'Not Validated', -6, 60, 160, null));

		insert sightingList;

		PageReference pageRef = Page.SightingsValidatorPage;
		Test.setCurrentPage(pageRef);
		SightingsValidatorController controller = new SightingsValidatorController();
		controller.validateType = 'Approve';
		/* get comma separated sightingIds */
		List<String> sightingIdList = new List<String>();
		for(Sighting__c sighting : sightingList){
			sightingIdList.add(sighting.Id);
		}
		controller.sightingIds = String.join(sightingIdList, ',');

		Test.startTest();
		controller.validate();
		Test.stopTest();

		List<Sighting__c> verifyList = [SELECT Id FROM Sighting__c WHERE Validation_Status__c = 'Approved'];
		System.assertEquals(verifyList.size(), 20);

		List<ApexPages.Message> messageList = ApexPages.getMessages();
		System.assertEquals(messageList.size(), 1);
		System.assertEquals(messageList[0].getSummary(), 'All selected records successfully approved.');
		System.assertEquals(messageList[0].getSeverity(), ApexPages.Severity.INFO);
	}

	/*
    * @scenario: test validate() method when reject without errors
	*/
	@isTest static void validate_reject_test() {
		List<Species__c> speciesList = TestUtils.createSpeciesListForInsert();
		insert speciesList;
		Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();
		List<Sighting__c> sightingList = new List<Sighting__c>();

		/*
			insert 10 Sighting records with Number_of_Animals__c set to 0, and the other 10 with Number_of_Animals__c set to non-zero values
		*/
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 10, 'Not Validated', -6, 60, 160, null));
		sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Black Bear'), 10, 0, 'Not Validated', -4, 60, 160, null));

		insert sightingList;

		PageReference pageRef = Page.SightingsValidatorPage;
		Test.setCurrentPage(pageRef);
		SightingsValidatorController controller = new SightingsValidatorController();
		controller.validateType = 'Reject';
		/* get comma separated sightingIds */
		List<String> sightingIdList = new List<String>();
		for(Sighting__c sighting : sightingList){
			sightingIdList.add(sighting.Id);
		}
		controller.sightingIds = String.join(sightingIdList, ',');

		Test.startTest();
		controller.validate();
		Test.stopTest();

		List<Sighting__c> verifyList = [SELECT Id FROM Sighting__c WHERE Validation_Status__c = 'Rejected'];
		System.assertEquals(verifyList.size(), 20);

		List<ApexPages.Message> messageList = ApexPages.getMessages();
		System.assertEquals(messageList.size(), 1);
		System.assertEquals(messageList[0].getSummary(), 'All selected records successfully rejected.');
		System.assertEquals(messageList[0].getSeverity(), ApexPages.Severity.INFO);
	}

	/*
    * @scenario: test search() method
	*/
	@isTest static void search_test() {
		/*
			1. create a user with "Data Validator" as Profile, (60,160) as Default Sighting Location, and "Birds" as Specialization
			2. add this user into "Bird Validator" public group
			P.S. criteria-based sharing rules can NOT be tested using Apex, so step 2 was only to bypass validUser_property validation (see "validUser_property_test" method above)
		*/
		User dataValidator = TestUtils.createTestUser('dataValidator','Data Validator', 60, 160, 'Birds');
		insert dataValidator;
		List<Group> groupList = [SELECT Id FROM Group WHERE Type='Regular' AND Name='Bird Validators'];
		System.assertEquals(groupList.size(), 1);
		GroupMember gm = new GroupMember();
		gm.GroupId = groupList[0].Id;
		gm.UserOrGroupId = dataValidator.Id;
		insert gm;

		/*
			insert 20 Sighting records with different locations
			P.S. use "dataValidator" user to perform insert so that the user have visiblity for all these records
			(given OWD for Sighting is private and criteria-based sharing rules are not supported in Apex)
		*/
		System.runAs(dataValidator){
			List<Species__c> speciesList = TestUtils.createSpeciesListForInsert();
			insert speciesList;
			Map<String, Id> speciesNameIdMap = TestUtils.getSpeciesNameIdMap();
			List<Sighting__c> sightingList = new List<Sighting__c>();
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Bald Eagle'), 10, 10, 'Not Validated', -6, 60, 160, null));
			sightingList.addAll(TestUtils.createSightingListForInsert(speciesNameIdMap.get('Brown Bear'), 10, 10, 'Not Validated', -6, -60, -160, null));
			insert sightingList;
		}

		List<Sighting__c> dataValidator_sightingList = new List<Sighting__c>();

		Test.startTest();

		System.runAs(dataValidator){
			PageReference pageRef = Page.SightingsValidatorPage;
			Test.setCurrentPage(pageRef);
			SightingsValidatorController controller = new SightingsValidatorController();

			while(true){
				dataValidator_sightingList.addAll(controller.getSightings());
				if(!controller.setCon.getHasNext()){
					break;
				}else{
					controller.setCon.next();
				}
			}

			/* verify the initial records returned by StandardSetController */
			System.assertEquals(dataValidator_sightingList.size(), 10);
			for(Sighting__c sighting : dataValidator_sightingList){
				System.assertEquals(sighting.Species__r.Name, 'Bald Eagle');
			}

			/* reset critera and search */
			controller.latitude = -60;
			controller.longitude = -160;
			controller.search();

			dataValidator_sightingList.clear();
			while(true){
				dataValidator_sightingList.addAll(controller.getSightings());
				if(!controller.setCon.getHasNext()){
					break;
				}else{
					controller.setCon.next();
				}
			}

			/* verify the new records returned by StandardSetController after search*/
			System.assertEquals(dataValidator_sightingList.size(), 10);
			for(Sighting__c sighting : dataValidator_sightingList){
				System.assertEquals(sighting.Species__r.Name, 'Brown Bear');
			}
		}

		Test.stopTest();
	}

	/*
    * @scenario: test getOptions() method
	*/
	@isTest static void getOptions_test() {
		PageReference pageRef = Page.SightingsValidatorPage;
		Test.setCurrentPage(pageRef);
		SightingsValidatorController controller = new SightingsValidatorController();

		List<SelectOption> options = controller.getOptions();
		System.assertEquals(options.size(), 3);
		System.assertEquals(options[0].getValue(), '100');
		System.assertEquals(options[1].getValue(), '150');
		System.assertEquals(options[2].getValue(), '200');
	}

}
