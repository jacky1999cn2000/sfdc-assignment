public class SightingsValidatorController {
	// current user
	public User validator { get; set; }

	// properties used for pagination
	public Integer noOfRecords{ get; set; }
  public Integer size{ get; set; }

	// properties used for SOQL query
	public String radius { get; set; }
	public Decimal latitude { get; set; }
	public Decimal longitude { get; set; }

	// comma delimited sighting ids for approve/reject (passed in by javascript function)
	public String sightingIds { get; set; }
	// indicate validate type (approve, reject, or reset)
	public String validateType { get; set; }

	// StandardSetController for pagination
	public ApexPages.StandardSetController setCon {
		get{
			if(setCon == null){
				try{
					size = 5;
					String queryString = 'SELECT Id,CreatedById,CreatedBy.Name,Date__c,Location__c,Location__Latitude__s,Location__Longitude__s,Number_of_Animals__c,Species__r.Name,Species__r.Rarity__c,Validation_Status__c FROM Sighting__c WHERE Validation_Status__c = \'Not Validated\' AND DISTANCE(Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'mi\') < ' + radius + ' ORDER BY Date__c ASC, Species__r.Name ASC';
					setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
					setCon.setPageSize(size);
					noOfRecords = setCon.getResultSize();
				}catch(Exception ex){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid \'Default Sighting Location\' value for the current user.'));
				}
			}

			return setCon;
		}
		set;
	}

	/*
		retrieve current user and initialize some properties
	*/
	public SightingsValidatorController() {
		validator = [SELECT Default_Sighting_Location__Latitude__s,Default_Sighting_Location__Longitude__s FROM User WHERE Id=:UserInfo.getUserId()];
		radius = '150';
		latitude = validator.Default_Sighting_Location__Latitude__s;
		longitude = validator.Default_Sighting_Location__Longitude__s;
	}

	/*
		get function for sightings
	*/
	public List<Sighting__c> getSightings(){
		List<Sighting__c> sightingList = new List<Sighting__c>();
		if(setCon != null){
			for(Sighting__c sighting : (List<Sighting__c>)setCon.getRecords())
				sightingList.add(sighting);
		}

		return sightingList;
	}

	/*
		get function for options
	*/
	public List<SelectOption> getOptions() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('100','100 km'));
    options.add(new SelectOption('150','150 km'));
    options.add(new SelectOption('200','200 km'));
    return options;
  }


	/*
		re-query sighting records based on current radius, latitude, and longitude properties
	*/
	public pageReference search() {
		setCon = null;
    getSightings();
    setCon.setPageNumber(1);
    return null;
  }

	/*
		handle approve, reject and reset actions
	*/
	public pageReference validate(){
		// only do the following for approve or reject
		if(validateType.toUpperCase() == 'APPROVE' || validateType.toUpperCase() == 'REJECT'){

			if(String.isEmpty(sightingIds)){
				// if no records being selected, then notify the user
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You haven\'t selected any records.'));
			}else{
				/*
					1. retrieve sightings based on ids
					2. update Validation_Status__c field
					3. partial save updated records
					4. display appropriate messages
				*/
				List<Id> sightingIdList = sightingIds.split(',');
				List<Sighting__c> sightingToUpdateList = [SELECT Id, Validation_Status__c FROM Sighting__c WHERE Id IN :sightingIdList];

				for(Sighting__c sighting : sightingToUpdateList){
					if(validateType.toUpperCase() == 'APPROVE'){
						sighting.Validation_Status__c = 'Approved';
					}else{
						sighting.Validation_Status__c = 'Rejected';
					}
				}

				Boolean allRecordsUpdatedSuccessfully = true;
				String message = '';

				Database.SaveResult[] srList = Database.update(sightingToUpdateList, false);

				for(Database.SaveResult sr : srList){
			    if(!sr.isSuccess()){
						allRecordsUpdatedSuccessfully = false;
						for(Database.Error err : sr.getErrors()) {
							message = err.getMessage();
			      }
			    }
				}

				if(allRecordsUpdatedSuccessfully){
					message = validateType.toUpperCase() == 'APPROVE' ? 'All selected records successfully approved.' : 'All selected records successfully rejected.';
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
				}else{
					message = 'Some of the records did not save.' + message + '.Please try again.';
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
				}
			}
		}

		setCon = null;
		getSightings();
		setCon.setPageNumber(1);

		return null;
	}
}