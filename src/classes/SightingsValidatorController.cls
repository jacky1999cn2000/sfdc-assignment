public class SightingsValidatorController {

	public User validator { get; set; }

	public Integer noOfRecords{ get; set; }
  public Integer size{ get; set; }

	public String radius { get; set; }
	public Decimal latitude { get; set; }
	public Decimal longitude { get; set; }

	public String sightingIds { get; set; }

	public String test {get;set;}

	public SightingsValidatorController() {
		test = 'initial';
		validator = [SELECT Default_Sighting_Location__Latitude__s,Default_Sighting_Location__Longitude__s FROM User WHERE Id=:UserInfo.getUserId()];
		radius = '150';
		latitude = validator.Default_Sighting_Location__Latitude__s;
		longitude = validator.Default_Sighting_Location__Longitude__s;
	}

	public ApexPages.StandardSetController setCon {
		get{
			if(setCon == null){
				System.debug('***setCon is null');
				size = 5;
				String queryString = 'SELECT Id,CreatedById,CreatedBy.Name,Date__c,Location__c,Location__Latitude__s,Location__Longitude__s,Number_of_Animals__c,Species__r.Name,Species__r.Rarity__c,Validation_Status__c FROM Sighting__c WHERE Validation_Status__c = \'Not Validated\' AND DISTANCE(Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'mi\') < ' + radius + ' ORDER BY Date__c ASC, Species__r.Name ASC';
				System.debug('***queryString '+queryString);
				setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
				setCon.setPageSize(size);
				noOfRecords = setCon.getResultSize();
			}else{
				System.debug('***setCon is NOT null');
			}
			return setCon;
		}
		set;
	}

	public List<Sighting__c> getSightings(){
		System.debug('***getSightings');
		List<Sighting__c> sightingList = new List<Sighting__c>();
		for(Sighting__c sighting : (List<Sighting__c>)setCon.getRecords())
			sightingList.add(sighting);

		for(Sighting__c sighting : sightingList)
			System.debug('***sighting: '+sighting.Species__r.Name);

		return sightingList;
	}

	public List<SelectOption> getOptions() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('100','100 km'));
    options.add(new SelectOption('150','150 km'));
    options.add(new SelectOption('200','200 km'));
    return options;
  }


	public pageReference search() {
    System.debug('***search!');
		System.debug('***radius '+radius);
		setCon = null;
    getSightings();
    setCon.setPageNumber(1);
    return null;
  }

	public pageReference approve(){
		System.debug('***approve!');

		test = 'changed';



		System.debug('***sightingIds:'+sightingIds);

		List<Id> sightingIdList = sightingIds.split(' ');
		System.debug('***sightingIdList '+sightingIdList);

		List<Sighting__c> sightingToUpdateList = [SELECT Id, Validation_Status__c FROM Sighting__c WHERE Id IN :sightingIdList];
		System.debug('***sightingToUpdateList '+sightingToUpdateList);

		for(Sighting__c sighting : sightingToUpdateList){
			sighting.Validation_Status__c = 'Approved';
		}

		Database.SaveResult[] srList = Database.update(sightingToUpdateList, false);

		// Iterate through each returned result
		for(Database.SaveResult sr : srList){
	    if(sr.isSuccess()){
        // Operation was successful, so get the ID of the record that was processed
        System.debug('***Successfully update Sighting__c. Sighting__c ID: ' + sr.getId());
	    }else{
	      // Operation failed, so get all errors
	      for(Database.Error err : sr.getErrors()) {
	          System.debug('***The following error has occurred.');
	          System.debug(err.getStatusCode() + ': ' + err.getMessage());
	          System.debug('***Account fields that affected this error: ' + err.getFields());
	      }
	    }
		}

		setCon = null;
		getSightings();
		setCon.setPageNumber(1);

		return null;
	}

	public pageReference reject(){
		return null;
	}

	public pageReference reset(){
		return null;
	}
}
