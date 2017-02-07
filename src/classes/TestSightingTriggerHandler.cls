@isTest
private class TestSightingTriggerHandler {

	private static List<String> speciesNameList = new List<String>{'Bald Eagle','Black Bear','Brown Bear','Gyrfalcon','Halibut','Orca','Polar Bear','Salmon','Snowy Owl','Trout'};
	private static Map<String, String> speciesNameGroupMap = new Map<String, String>{'Bald Eagle' => 'Birds','Black Bear' => 'Mammals','Brown Bear' => 'Mammals','Gyrfalcon' => 'Birds','Halibut' => 'Fish','Orca' => 'Mammals','Polar Bear' => 'Mammals','Salmon' => 'Fish','Snowy Owl' => 'Birds','Trout' => 'Fish'};

	/*
    * @scenario: test trigger works correctly after bulk insert

			insert 300 Sighting records:

				Bald Eagle (records number: 50, total animal seen: 0, 	status: approved, date: within past 12 months),
				Black Bear (records number: 50, total animal seen: 50,  status: approved, date: within past 12 months),
				Brown Bear (records number: 50, total animal seen: 200, status: approved, date: within past 12 months),
				Gyrfalcon	 (records number: 50, total animal seen: 500, status: approved, date: within past 12 months),

				Halibut		 (records number: 50, total animal seen: 200, status: rejected, date: within past 12 months),
				Orca			 (records number: 50, total animal seen: 200, status: approved, date: not within past 12 months)
  */
	@isTest static void bulk_insert() {
		Map<String, Id> speciesNameIdMap = createSpecies();
		List<Sighting__c> sightingList = new List<Sighting__c>();

		sightingList.addAll(createSightings(speciesNameIdMap, 50, 0, 'Approved', 'Bald Eagle', true, null, null, null));
		sightingList.addAll(createSightings(speciesNameIdMap, 50, 50, 'Approved', 'Black Bear', true, null, null, null));
		sightingList.addAll(createSightings(speciesNameIdMap, 50, 200, 'Approved', 'Brown Bear', true, null, null, null));
		sightingList.addAll(createSightings(speciesNameIdMap, 50, 500, 'Approved', 'Gyrfalcon', true, null, null, null));
		sightingList.addAll(createSightings(speciesNameIdMap, 50, 200, 'Rejected', 'Halibut', true, null, null, null));
		sightingList.addAll(createSightings(speciesNameIdMap, 50, 200, 'Approved', 'Orca', false, null, null, null));

		Test.startTest();
		Database.insert(sightingList, false);
		Test.stopTest();

		List<Species__c> speciesList = [SELECT Name, Rarity__c FROM Species__c];
		for(Species__c species : speciesList){
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
			}
		}
	}

	/*
    * @scenario: test trigger works correctly after bulk insert
			insert 500 Sighting records:

				Bald Eagle (records number: 50, total animal seen: 0, 	status: approved, date: within past 12 months),
				Black Bear (records number: 50, total animal seen: 50,  status: approved, date: within past 12 months),
				Brown Bear (records number: 50, total animal seen: 200, status: approved, date: within past 12 months),
				Gyrfalcon	 (records number: 50, total animal seen: 500, status: approved, date: within past 12 months),

				Halibut		 (records number: 50, total animal seen: 200, status: rejected, date: within past 12 months),
				Orca			 (records number: 50, total animal seen: 200, status: approved, date: not within past 12 months),
				Polar Bear (records number: 50, total animal seen: null,status: approved, date: within past 12 months),
				Salmon		 (records number: 50, total animal seen: 500, status: approved, date: within past 12 months),
				Snowy Owl	 (records number: 50, total animal seen: null,status: approved, date: within past 12 months),
				Trout		   (records number: 50, total animal seen: 500, status: approved, date: within past 12 months)
  */


	/*
    * @description: create/insert 10 Species
    * @return: a Map with Species Name as key, corresponding Species Id as value
  */
	private static Map<String, Id> createSpecies(){

		List<Species__c> speciesList = new List<Species__c>();

		for(Integer i=0; i<speciesNameList.size(); i++){
			Species__c species = (Species__c)Species__c.SObjectType.newSObject(null, true);
			species.Name = speciesNameList[i];
			species.Species_Group__c = speciesNameGroupMap.get(speciesNameList[i]);
			speciesList.add(species);
		}

		insert speciesList;

		Map<String, Id> speciesNameIdMap = new Map<String, Id>();

		for(Species__c species : speciesList){
			speciesNameIdMap.put(species.Name, species.Id);
		}

		return speciesNameIdMap;
	}

	/*
    * @description: create a list of Sightings with designated parameters
		* @param: speciesNameIdMap, Map with Species Name as key, corresponding Species Id as value
		* @param: recordNumber, the total number of records
		* @param: animalNumber, the total number of seen animal (this number should be recordNumber*x)
		* @param: validationStatus, value for validation status
		* @param: speciesName, name for related Species
		* @param: validDate, indicate whether the date field is within past 12 months or not
		* @param: latitude, latitude for Location (default to 61.00)
		* @param: longitude, latitude for Location (default to -160.00)
		* @param: precision, value for Location Precision (default to 10 meters)
    * @return: a List of Sightings
  */
	private static List<Sighting__c> createSightings(Map<String, Id> speciesNameIdMap, Integer recordNumber, Integer animalNumber, String validationStatus, String speciesName, Boolean validDate, Double latitude, Double longitude, String precision){

		latitude = latitude == null ? 61.00 : latitude;
		longitude = longitude == null ? -160.00 : longitude;
		precision = precision == null ? '10 meters' : precision;

		Integer averageAnimalNumber = animalNumber/recordNumber;

		List<Sighting__c> sightingList = new List<Sighting__c>();

		for(Integer i=0; i<recordNumber; i++){
			Sighting__c sighting = (Sighting__c)Sighting__c.SObjectType.newSObject(null, true);
			sighting.Date__c = validDate ? Date.today().addMonths(-6) : Date.today().addMonths(-16);
			sighting.Location__Latitude__s = latitude;
			sighting.Location__Longitude__s = longitude;
			sighting.Location_Precision__c = precision;
			sighting.Number_of_Animals__c = averageAnimalNumber;
			sighting.Species__c = speciesNameIdMap.get(speciesName);
			sighting.Validation_Status__c = validationStatus;
			sightingList.add(sighting);
		}

		return sightingList;
	}

}
