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

// toggle checkboxes' status when clicking the "select all" checkbox
function selectAll(){
  console.log('selectAll');

  countSelection();

  console.log('checkedNumber ',checkedNumber);

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

// sync selectedIdArray based on checkboxes' status
function saveSelection(){
  console.log('saveSelection');

  selectedIdString = selectedIdArray.join(' ');

  document.querySelectorAll("input[type='checkbox']").forEach(function(element){
    if(element.checked){
      if(element.id != 'selectallsightingscheckbox' && selectedIdString.indexOf(element.id) == -1){
        selectedIdArray.push(element.id);
        selectedIdString = selectedIdString + ' ' + element.id;
      }
    }else{
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

function restoreSelection(){
  console.log('restoreSelection');

  selectedIdString = selectedIdArray.join(' ');
  document.querySelectorAll("input[type='checkbox']").forEach(function(element){
    if(selectedIdString.indexOf(element.id) != -1){
      element.checked = true;
    }
  });

  countSelection();
  if(checkedNumber == availableCheckboxes()){
    document.getElementById('selectallsightingscheckbox').checked = true;
  }
}
