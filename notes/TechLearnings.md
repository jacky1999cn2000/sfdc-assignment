# Tech Learnings

* Remove a column from .csv file and save the result into a new file `cut -d, -f2-13 Sightings.csv > Sightings-copy.csv`

* [Visualforce Tags with Examples](http://sfdcsrini.blogspot.com/2014/06/visualforce-form-tags-with-examples.html)

* [Visualforce Tab Icon](http://salesforce.stackexchange.com/questions/32026/how-to-display-sfdc-standard-icons-on-vf-page)

* [ngrok](https://ngrok.com/)

**TERMINAL 1**
```
  cd assets
  serve
```
**TERMINAL 2**
```
  cd assets
  ngrok http 3000
```
![1.png](/notes/imgs/1.png)

* [Pagination with StandardSetController](https://hisrinu.wordpress.com/2012/01/09/pagination-using-standardsetcontroller/)

* [Pagination with surviving checkbox status](http://stackoverflow.com/questions/14823107/how-to-find-out-which-checkboxes-have-been-selected-on-the-next-page-in-visualfo/14825189#14825189)

* For `<apex:commandButton/>`:
  * if didn't provide a `reRender` attribute, then clicking the button will cause a full page refresh (no matter the corresponding apex function return pageReference or not), and data stored in Javascript will be lost due to it, e.g. `<apex:commandButton action="{!reset}" value="Reset"/>`
  * if provide a `reRender` attribute, then clicking the button will cause a ajax call (only the designated part of the page being refreshed), and data stored in Javascript will be persisted, e.g. `<apex:commandButton reRender="overview,details" action="{!reset}" value="Reset"/>`
  * of course, if you want to restore status after click the button (status was stored in Javascript data), you can use `oncomplete` attribute, e.g. `<apex:commandButton reRender="overview,details" action="{!reset}" value="Reset" oncomplete="restoreSelection()"/>`

* When trying to use `onclick` attribute in `<apex:commandButton/>` to call a javascript function defined by `<apex:actionFunction/>` which in turn call a function defined in apex controller, e.g. `<apex:commandButton onclick="approve(selectedIdString);clearSelection();return false;" value="Approve"/>`, then there are some hidden issues:
  * first, understand the race condition if not use `return false;` or `reRender`:
    * [article 1](http://salesforce.stackexchange.com/questions/101431/race-condition-between-commandlink-and-actionfunction)
    * [article 2](http://stackoverflow.com/questions/11893895/apexactionfunction-and-database-update-unintended-page-refresh)
  * so, we used the `return false;` to avoid the default full page reload behavior; however, we need to refresh parts of the the page, and this was done by setting `reRender` attribute in `<apex:actionFunction/>` (see below)
  * in addition, in order to pass parameter into the function defined by <apex:actionFunction/>, you have to provide a `reRender` attribute, and in this case, we rerender `overview`,`details` and `messages` pageBlocks.
  ```
  <apex:actionFunction action="{!approve}" name="approve" reRender="overview,details,messages">
    <apex:param name="sightingIds" assignTo="{!sightingIds}" value="" />
  </apex:actionFunction>
  ```

* [Delete classes & triggers from Production Organizaiton via Workbench](http://www.salesforceben.com/way-to-delete-apex-classes-from-production/)

* [Detailed explanations about different messaging options in Visualforce](http://salesforce.stackexchange.com/questions/8139/difference-between-the-multiple-messaging-options-in-visualforce)

* [Partial success and trigger firing](http://cropredysfdc.com/2015/04/26/245/)
* [Partial success and trigger firing documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dml_bulk_exceptions.htm)

* [Migrate ListView with ChangeSet](http://www.simplysfdc.com/2014/03/salesforce-list-view-not-visible-in.html)

* [Custom List View to display VF Page](http://salesforce.stackexchange.com/questions/32067/custom-list-view-to-display-vf-page)
