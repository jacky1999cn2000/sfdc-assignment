// array to store all selected sighting ids
var selectedIdArray = [];
var selectedIdString,checkedNumber;

// calculate number of checkboxes on current page (exclude "select all" checkbox)
function availableCheckboxes(){
  return document.querySelectorAll("input[type='checkbox']").length - 1;
}

// count how many checkboxes were checked on current page (exclude "select all" checkbox)
function countSelection(){
  checkedNumber = 0;
  document.querySelectorAll("input[type='checkbox']").forEach(function(element){
    if(element.id != 'selectallsightingscheckbox' && element.checked){
      checkedNumber++;
    }
  });
}

// update checkboxes' statuses when clicking the "select all" checkbox
function selectAll(){
  countSelection();

  // select all or unselect all
  if(checkedNumber == availableCheckboxes()){
    document.querySelectorAll("input[type='checkbox']").forEach(function(element){
      element.checked = false;
    });
  }else{
    document.querySelectorAll("input[type='checkbox']").forEach(function(element){
      element.checked = true;
    });
  }

  saveSelection();
}

// update selectedIdArray based on checkboxes
function saveSelection(){
  selectedIdString = selectedIdArray.join(' ');

  document.querySelectorAll("input[type='checkbox']").forEach(function(element){
    if(element.checked){
      // need to exclude "select all" checkbox
      if(element.id != 'selectallsightingscheckbox' && selectedIdString.indexOf(element.id) == -1){
        selectedIdArray.push(element.id);
        selectedIdString = selectedIdString + ' ' + element.id;
      }
    }else{
      // if there was one unchecked checkbox, then uncheck "select all" checkbox
      document.getElementById('selectallsightingscheckbox').checked = false;

      if(selectedIdString.indexOf(element.id) != -1){
        for(i=0; i<selectedIdArray.length; i++){
          if(selectedIdArray[i] == element.id){
            selectedIdArray.splice(i,1);
            selectedIdString = selectedIdArray.join(' ');
          }
        }
      }
    }
  });

  console.log('selectedIdArray ',selectedIdArray);
}

// restore checked checkboxes based on selectedIdArray
function restoreSelection(){
  selectedIdString = selectedIdArray.join(' ');

  // check corresponding checkbox if its id was found in selectedIdString
  document.querySelectorAll("input[type='checkbox']").forEach(function(element){
    if(selectedIdString.indexOf(element.id) != -1){
      element.checked = true;
    }
  });

  // if all checkboxes checked on the page, then check "select all" checkbox
  countSelection();
  if(checkedNumber == availableCheckboxes()){
    document.getElementById('selectallsightingscheckbox').checked = true;
  }
}

// clear all selections after clicking search button
function clearSelection(){
  selectedIdArray = [];
  selectedIdString = '';
}
