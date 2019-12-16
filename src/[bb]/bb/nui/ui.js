
$(function() {
	
	var menu = $("#main-menu");
	
	window.addEventListener('message', function(event) {
		
		var item = event.data;
		if (item.showmenu) { menu.show(); }
		if (item.hidemenu) { menu.hide(); }
    
	});
	
  // Pressing the ESC key with the menu open closes it 
  document.onkeyup = function (data) {
    if (data.which == 27) {
      if (menu.is( ":visible" )) {ExitMenu();}
    }
  };
	
});

function ExitMenu() {
	$.post('http://bb/MainMenu', JSON.stringify({action:"exit"}));
}
