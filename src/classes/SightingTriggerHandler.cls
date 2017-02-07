public with sharing class SightingTriggerHandler {

	public static void handleTrigger(Map<Id,Sighting__c> sightingMap){

		// iterate all sighting records passed in, and add related species Ids into speciesIdSet
		Set<Id> speciesIdSet = new Set<Id>();

		for(Sighting__c sighting : sightingMap.values()){
			speciesIdSet.add(sighting.Species__c);
		}

		// retrieve related species records for later update
		List<Species__c> speciesList = [SELECT Id, Rarity__c FROM Species__c WHERE Id IN : speciesIdSet];

		// use aggregate soql to retrieve the total numbers of animals seen of approved sightings within the last 12 month for all related species
		List<AggregateResult> arList = [SELECT Species__c,SUM(Number_of_Animals__c) Total FROM Sighting__c WHERE Validation_Status__c = 'Approved' AND CreatedDate = LAST_N_MONTHS:12 AND Species__c IN : speciesIdSet GROUP BY Species__c];

		// create a map with species Id as key, and total number of animal seen as value
		Map<Id, Integer> speciesNumberOfAnimalMap = new Map<Id, Integer>();

		for(AggregateResult ar: arList){
			speciesNumberOfAnimalMap.put((ID)ar.get('Species__c'), Integer.ValueOf(ar.get('Total')));
		}

		// iterate each related species and perform update
		for(Species__c species : speciesList){
			species.Rarity__c = getRarityValue(speciesNumberOfAnimalMap.get(species.Id));
		}

		update speciesList;
	}

	/*
		get corresponding value for Rarity__c
	*/
	private static String getRarityValue(Integer totalNumberOfAnimal){
		if(totalNumberOfAnimal == 0 || totalNumberOfAnimal == null){
			return 'Extinct';
		}else if(totalNumberOfAnimal >= 1 && totalNumberOfAnimal <= 100){
			return 'Endangered';
		}else if(totalNumberOfAnimal >= 101 && totalNumberOfAnimal <= 400){
			return 'Rare';
		}else{
			return 'Common';
		}
	}

}
