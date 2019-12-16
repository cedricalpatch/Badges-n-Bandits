
$(function() {
	
	var connect = $("#connect-menu");
	
	window.addEventListener('message', function(event) {
		
		var item = event.data;
		if (item.showconnect) { connect.show(); }
		if (item.hideconnect) { connect.hide(); }
    
	});
	
  // Pressing the ESC key with the menu open closes it 
  document.onkeyup = function (data) {
    if (data.which == 27) {
      if (connect.is( ":visible" )) {ExitMenu();}
    }
  };
	
});

function ExitMenu() {
	$.post('http://bb_connect/ConnectMenu', JSON.stringify({action:"exit"}));
}
