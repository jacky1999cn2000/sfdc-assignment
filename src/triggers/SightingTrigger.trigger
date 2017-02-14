trigger SightingTrigger on Sighting__c (after insert, after update) {
  SightingTriggerHandler.handleTrigger(Trigger.newMap);
}