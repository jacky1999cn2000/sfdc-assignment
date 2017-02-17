@isTest
public class TestUtils {

	/* predefined species list that would be created in testSetup */
	public static List<String> speciesNameList = new List<String>{'Bald Eagle','Black Bear','Brown Bear','Gyrfalcon','Halibut','Orca','Polar Bear','Salmon','Snowy Owl','Trout'};
	/* species group map - used when creating species */
	public static Map<String, String> speciesNameGroupMap = new Map<String, String>{'Bald Eagle' => 'Birds','Black Bear' => 'Mammals','Brown Bear' => 'Mammals','Gyrfalcon' => 'Birds','Halibut' => 'Fish','Orca' => 'Mammals','Polar Bear' => 'Mammals','Salmon' => 'Fish','Snowy Owl' => 'Birds','Trout' => 'Fish'};

	/*
    * @description: create predefined Species
    * @return: a List of Species
  */
	public static List<Species__c> createSpeciesListForInsert(){

		List<Species__c> speciesList = new List<Species__c>();

		for(Integer i=0; i<speciesNameList.size(); i++){
			Species__c species = (Species__c)Species__c.SObjectType.newSObject(null, true);
			species.Name = speciesNameList[i];
			species.Species_Group__c = speciesNameGroupMap.get(speciesNameList[i]);
			speciesList.add(species);
		}

		return speciesList;
	}

	/*
    * @description: create a list of Sightings with designated parameters
		* @param: speciesId, related Species Id for Sightings
		* @param: recordNumber, the total number of records
		* @param: animalNumber, the total number of seen animal (this number should be recordNumber*X while X is Integer)
		* @param: validationStatus, value for validation status
		* @param: monthFromToday, used to calculate Date__c, indicating how many months ago the date was compared to today
		* @param: latitude, latitude for Location (default to 61.00)
		* @param: longitude, latitude for Location (default to -160.00)
		* @param: precision, value for Location Precision (default to 10 meters)
    * @return: a List of Sightings
  */
	public static List<Sighting__c> createSightingListForInsert(Id speciesId, Integer recordNumber, Integer animalNumber, String validationStatus, Integer monthFromToday, Double latitude, Double longitude, String precision){

		latitude = latitude == null ? 60.00 : latitude;
		longitude = longitude == null ? -160.00 : longitude;
		precision = precision == null ? '10 meters' : precision;

		Integer averageAnimalNumber = animalNumber/recordNumber;

		List<Sighting__c> sightingList = new List<Sighting__c>();

		for(Integer i=0; i<recordNumber; i++){
			Sighting__c sighting = (Sighting__c)Sighting__c.SObjectType.newSObject(null, true);
			sighting.Date__c = Date.today().addMonths(monthFromToday);
			sighting.Location__Latitude__s = latitude;
			sighting.Location__Longitude__s = longitude;
			sighting.Location_Precision__c = precision;
			sighting.Number_of_Animals__c = averageAnimalNumber;
			sighting.Species__c = speciesId;
			sighting.Validation_Status__c = validationStatus;
			sightingList.add(sighting);
		}

		return sightingList;
	}

	/*
    * @description: create a list of Sightings with designated parameters
		* @param: speciesId, related Species Id for Sightings
		* @param: recordNumber, the total number of records
		* @param: animalNumber, the total number of seen animal (this number should be recordNumber*X while X is Integer)
		* @param: validationStatus, value for validation status
		* @param: monthFromToday, used to calculate Date__c, indicating how many months ago the date was compared to today
		* @param: latitude, latitude for Location (default to 61.00)
		* @param: longitude, latitude for Location (default to -160.00)
		* @param: precision, value for Location Precision (default to 10 meters)
    * @return: a List of Sightings
  */
	public static List<Sighting__c> createSightingListForUpdate(Id speciesId, Integer recordNumber, Integer animalNumber, String validationStatus, Integer monthFromToday, Double latitude, Double longitude, String precision){

		Integer averageAnimalNumber = animalNumber/recordNumber;

		List<Sighting__c> sightingList = [SELECT Id, Date__c, Location__Latitude__s, Location__Longitude__s, Location_Precision__c, Number_of_Animals__c, Validation_Status__c, Species__c FROM Sighting__c WHERE Species__c = : speciesId];

		for(Sighting__c sighting : sightingList){

			sighting.Date__c = Date.today().addMonths(monthFromToday);
			sighting.Number_of_Animals__c = averageAnimalNumber;

			if(validationStatus != null){
				sighting.Validation_Status__c = validationStatus;
			}
			if(latitude != null){
				sighting.Location__Latitude__s = latitude;
			}
			if(longitude != null){
				sighting.Location__Longitude__s = longitude;
			}
			if(precision != null){
				sighting.Location_Precision__c = precision;
			}
		}

		return sightingList;
	}

	/*
    * @description: get a Map of Species Name as key and Species Id as value
    * @return: a Map of Species Name as key and Species Id as value
  */
	public static Map<String, Id> getSpeciesNameIdMap(){
		Map<String, Id> speciesNameIdMap = new Map<String, Id>();

		List<Species__c> speciesList = [SELECT Id, Name FROM Species__c];
		for(Species__c species : speciesList){
			speciesNameIdMap.put(species.Name, species.Id);
		}

		return speciesNameIdMap;
	}

	/*
    * @description: get an unique prefix for username creation
    * @return: a unique string
  */
	public static String getUserNamePrefix(){
    return UserInfo.getOrganizationId() + System.now().millisecond();
  }

	/*
    * @description: create a User with designated parameters
		* @param: userName, used to create username
		* @param: profileName, used to assign profile
		* @param: latitude, latitude for Default_Sighting_Location__c (default to 61.00)
		* @param: longitude, latitude for Default_Sighting_Location__c (default to -160.00)
		* @param: specialization, value for Validation_Specialization__c
    * @return: a User
  */
	public static User createTestUser(String userName, String profileName, Decimal latitude, Decimal longitude, String specialization){
		latitude = latitude == null ? 61.00 : latitude;
		longitude = longitude == null ? -160.00 : longitude;

		Profile p = [SELECT Id FROM Profile WHERE Name=: profileName];
		String email = userName+'@test.com';
		String uniqueUserName = getUserNamePrefix() + email;
    User u = new User(Alias=userName.left(3), Email=email, UserName=uniqueUserName, Default_Sighting_Location__Latitude__s=latitude, Default_Sighting_Location__Longitude__s=longitude, Validation_Specialization__c=specialization, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles');
		return u;
	}

}