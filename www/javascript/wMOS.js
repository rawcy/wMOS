//////////////////////////////////////////////
//  Author:       Yin Chen                  //                     
//  Contact:      yinche@cisco.com          //
//  Data:         May 9 2013                //
//  Project:      wMOS                      //
//////////////////////////////////////////////


function pageload()
{
	alert('Hit OK, and then wait for the page to be loaded.');
}


function checkMACAddress() {
	var macAddress=document.getElementById('mac').value;
	var macAddressRegExp=/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/i;
	var mavFF=/^([0|F|f]{2}:){5}[0|F|f]{2}$/i;
	
	if (mavFF.test(macAddress) == true) {
		alert("please enter a valid mac address\nexample XX:XX:XX:XX:XX:XX\nX = 0-9,A-F,a-f");
		return false;
	}
	
	if(macAddress.length!=17) {
		alert('Mac Address is not the proper length.');
		return false;
	}

	if (macAddressRegExp.test(macAddress)==false) { //if match failed
		alert("Please enter a valid MAC Address.\nexample XX:XX:XX:XX:XX:XX\nX = 0-9,A-F,a-f");
		return false;
	}
	
	pageload();
	
	return true;
}
