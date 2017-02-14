public class SightingTriggerHandler {

	/*
    * @description: update related Species's Rarity field whenever there is any change to Sighting
    * @param: sightingMap, the newly updated or inserted Sighting records (Trigger.newMap)
    * @return: none
  */
	public static void handleTrigger(Map<Id,Sighting__c> sightingMap){

		// iterate Sighting records that were passed in, and add their related Species Ids into a Set
		Set<Id> speciesIdSet = new Set<Id>();

		for(Sighting__c sighting : sightingMap.values()){
			speciesIdSet.add(sighting.Species__c);
		}

		// System.debug('***speciesIdSet '+speciesIdSet);

		// retrieve related Species records for later update
		List<Species__c> speciesList = [SELECT Id, Rarity__c FROM Species__c WHERE Id IN : speciesIdSet];

		// for related Species, use Aggregate SOQL to retrieve total numbers of animals seen for approved Sightings within the last 12 months
		List<AggregateResult> arList = [SELECT Species__c,SUM(Number_of_Animals__c) Total FROM Sighting__c WHERE Validation_Status__c = 'Approved' AND Date__c = LAST_N_MONTHS:12 AND Species__c IN : speciesIdSet GROUP BY Species__c];

		// create a map with Species Id as key, and total number of animal seen as value
		Map<Id, Integer> speciesNumberOfAnimalMap = new Map<Id, Integer>();

		for(AggregateResult ar: arList){
			speciesNumberOfAnimalMap.put((ID)ar.get('Species__c'), Integer.ValueOf(ar.get('Total')));
		}

		// System.debug('***speciesNumberOfAnimalMap '+speciesNumberOfAnimalMap);

		// iterate each related Species, update Rarity field, and perform DML
		for(Species__c species : speciesList){
			species.Rarity__c = getRarityValue(speciesNumberOfAnimalMap.get(species.Id));
		}

		// System.debug('***speciesList '+speciesList);

		update speciesList;
	}

	/*
    * @description: return corresponding Rarity value based on parameter
    * @param: totalNumberOfAnimal, the total number of animal seen
    * @return: a corresponding Rarity value
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
