public class SightingsValidatorController {

	public User validator { get; set; }

	public Integer noOfRecords{ get; set; }
  public Integer size{ get; set; }


	public SightingsValidatorController() {
		validator = [SELECT Default_Sighting_Location__Latitude__s,Default_Sighting_Location__Longitude__s FROM User WHERE Id=:UserInfo.getUserId()];
	}

	public ApexPages.StandardSetController setCon {
		get{
			if(setCon == null){
				size = 5;
				String queryString = 'SELECT Id,CreatedById,CreatedBy.Name,Date__c,Location__c,Location__Latitude__s,Location__Longitude__s,Number_of_Animals__c,Species__r.Name,Species__r.Rarity__c,Validation_Status__c FROM Sighting__c WHERE Validation_Status__c = \'Not Validated\' AND DISTANCE(Location__c, GEOLOCATION(' + validator.Default_Sighting_Location__Latitude__s + ',' + validator.Default_Sighting_Location__Longitude__s + '), \'mi\') < 150 ORDER BY Date__c ASC, Species__r.Name ASC';
				System.debug('***queryString '+queryString);
				setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
				setCon.setPageSize(size);
				noOfRecords = setCon.getResultSize();
			}
			return setCon;
		}
		set;
	}

	public List<Sighting__c> getSightings(){
		List<Sighting__c> sightingList = new List<Sighting__c>();
		for(Sighting__c sighting : (List<Sighting__c>)setCon.getRecords())
			sightingList.add(sighting);
		return sightingList;
	}

	// public String test {
	// 	get{
	// 		if(test == null){
	// 			test = 'initial value';
	// 		}
	// 		return test;
	// 	}
	// 	private set;
	// }

	public pageReference search() {
    System.debug('***search!');
		//  test = 'test';
        return null;
  }






    public pageReference refresh() {
        setCon = null;
        // getAccounts();
        setCon.setPageNumber(1);
        return null;
    }
}
