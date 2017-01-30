public class SightingsValidatorController {

	public User validator { get; set; }

	public Integer noOfRecords{ get; set; }
  public Integer size{ get; set; }

	public String radius { get; set; }
	public Decimal latitude { get; set; }
	public Decimal longitude { get; set; }


	public SightingsValidatorController() {
		validator = [SELECT Default_Sighting_Location__Latitude__s,Default_Sighting_Location__Longitude__s FROM User WHERE Id=:UserInfo.getUserId()];
		radius = '150';
		latitude = validator.Default_Sighting_Location__Latitude__s;
		longitude = validator.Default_Sighting_Location__Longitude__s;
	}

	public ApexPages.StandardSetController setCon {
		get{
			if(setCon == null){
				size = 5;
				String queryString = 'SELECT Id,CreatedById,CreatedBy.Name,Date__c,Location__c,Location__Latitude__s,Location__Longitude__s,Number_of_Animals__c,Species__r.Name,Species__r.Rarity__c,Validation_Status__c FROM Sighting__c WHERE Validation_Status__c = \'Not Validated\' AND DISTANCE(Location__c, GEOLOCATION(' + latitude + ',' + longitude + '), \'mi\') < ' + radius + ' ORDER BY Date__c ASC, Species__r.Name ASC';
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
}
