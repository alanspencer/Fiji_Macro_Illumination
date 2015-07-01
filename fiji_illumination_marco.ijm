//-------------------------------------------------------------------------------------------------------------------//
// Macro Plugin for FIJI / ImageJ2 - Written by A.R.T. Spencer                                                       //
//
// To use this macro: First import a stack into Fiji or ImageJ2. Then go to "Plugins > Macros > Run..." and select   //
// this file. This will open up a dialog with various input options. Once these have been inputed/selcted click OK.  //
// If no errors have been found you will now see a directory select dialog, chose the ouput directory for your new   //
// stack. The macro will now run though each image in the stack creating a new image in your selected output folder  //
// based on your input settings.
//-------------------------------------------------------------------------------------------------------------------//

macro "Stack Illumination" {

// Check the type of ROI that has been used
function checkROI(mintype,maxtype,notype) {
	if ((selectionType() < mintype)||(selectionType() > maxtype)||(selectionType() == notype)||(selectionType() == -1)){
		if ((mintype == 3) && (maxtype == 7)) exit("Select a line ROI");
		if ((mintype == 0) && (maxtype == 3)) exit("Select an area ROI");
		else exit("Select a suitable ROI");
	}
}

// Date Function
function currentDate() {
	monthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
    dayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
    
    timeStr = dayNames[dayOfWeek]+" ";
	if (dayOfMonth<10) {timeStr = timeStr+"0";}
	timeStr = timeStr+dayOfMonth+"-"+monthNames[month]+"-"+year+"\nTime: ";
	if (hour<10) {timeStr = TimeStr+"0";}
	timeStr = timeStr+hour+":";
	if (minute<10) {timeStr = timeStr+"0";}
	timeStr = timeStr+minute+":";
	if (second<10) {timeStr = timeStr+"0";}
	timeStr = timeStr+second;
	
	return timeStr;
}

// Setup Dialog function
function setupDialog(startImage, endImage, minValue, maxValue, outputFormat, createInfoFile, runNormalize, saturateValue, runNormalizeByReference, referenceImageValue, runDespeckle, runBrightnessContrast, runMultiply, multiplyValue) {
	Dialog.create("Enter Input Data");
	Dialog.addMessage("The following information is required:");
	Dialog.addSlider("Start Image", 1, nSlices, startImage);
	Dialog.addSlider("End Image", 1, nSlices, endImage);
	Dialog.addChoice("Output Format", newArray("bmp","png","tiff"), outputFormat);  	
	Dialog.addRadioButtonGroup("Create Information File", newArray("Yes","No"), 1, 2, createInfoFile);
	
	Dialog.addMessage("(Optional) Multiply slices by custom value:");
	Dialog.addRadioButtonGroup("Multiply", newArray("Yes","No"), 1, 2, runMultiply);
 	Dialog.addNumber("Multiply Value", multiplyValue);
	
	Dialog.addMessage("(Optional) Normalize the Images in the Stack individually:");
	Dialog.addRadioButtonGroup("Normalize Images in Stack?", newArray("Yes","No"), 1, 2, runNormalize);
	Dialog.addNumber("Saturated Value", saturateValue);
	
	Dialog.addMessage("(Optional) To use the 'Normalize Stack by Reference Image' you\nneed to chose an image and optionaly draw a ROI before running this macro.");
	Dialog.addRadioButtonGroup("Normalize Stack by Reference Image?", newArray("Yes","No"), 1, 2, runNormalizeByReference);
	Dialog.addSlider("Reference Image", 1, nSlices, referenceImageValue);

	Dialog.addMessage("(Optional) Alter Brightness/Contrast:");
	Dialog.addRadioButtonGroup("Brightness/Contrast", newArray("Yes","No", "Auto"), 1, 2, runBrightnessContrast);
 	Dialog.addNumber("Min Value", minValue);
	Dialog.addNumber("Max Value", maxValue);

	Dialog.addMessage("(Optional) Despeckle Image before saving?");
	
	Dialog.addRadioButtonGroup("Despeckle Images in Stack?", newArray("Yes","No"), 1, 2, runDespeckle);
	
	Dialog.show();
}

// Check that there is a stack available
if (nSlices==0) exit("Stack required");

// Get Input Values from dialog
error = 1;
loop = 1;
while(error == 1) {
	
	if (loop == 1) {
		setupDialog(1, nSlices, 0.00, 255.00, "bmp", "Yes", "No", 0.4, "No", getSliceNumber(), "No", "Yes", "No", 2000000.00);
	} else {
		setupDialog(startImage, endImage, minValue, maxValue, outputFormat, createInfoFile, runNormalize, saturateValue, runNormalizeByReference, referenceImageValue, runDespeckle, runBrightnessContrast, runMultiply, multiplyValue);		
	}
	
	startImage = Dialog.getNumber();
	endImage = Dialog.getNumber();
  	outputFormat = Dialog.getChoice();
	createInfoFile = Dialog.getRadioButton();
	runMultiply = Dialog.getRadioButton();
	multiplyValue = d2s(Dialog.getNumber(), 2);
  	runNormalize = Dialog.getRadioButton();
	saturateValue = Dialog.getNumber();
	runNormalizeByReference = Dialog.getRadioButton();
	referenceImageValue = Dialog.getNumber();
  	runBrightnessContrast = Dialog.getRadioButton();
	minValue = d2s(Dialog.getNumber(), 2);
	maxValue = d2s(Dialog.getNumber(), 2);
	runDespeckle = Dialog.getRadioButton();
	
	// Error Check Inputs	
	errorText = "";
	error = 0;
	if (startImage < 0) {
		errorText = errorText+"- Your Start Image is less than 0.\n";
		error = 1;
	}
	if (startImage > nSlices) {
		errorText = errorText+"- Your Start Image greater than the number of slices.\n";
		error = 1;
	}
	if (endImage < 0) {
		errorText = errorText+"- Your End Image is less than 0.\n";
		error = 1;
	}
	if (endImage > nSlices) {
		errorText = errorText+"- Your End Image greater than the number of slices.\n";
		error = 1;
	}
	if (runNormalize == "Yes" && runNormalizeByReference == "Yes") {
		errorText = errorText+"- You can not select 'Normalize Images in Stack' and 'Normalize Stack by Reference Image'. Please only select one of these options.\n";
		error = 1;
	}
	if ((runNormalize == "Yes") && (saturateValue <= 0)) {
		errorText = errorText+"- Your Saturate Value is below or equal to 0.\n";
		error = 1;
	}
	if ((runNormalizeByReference == "Yes") && (referenceImageValue > nSlices)) {
		errorText = errorText+"- Your Reference Image number is above the number of slices in the stack.\n";
		error = 1;
	}
	
	if (error == 1) {
		Dialog.create("Enter Input Data - ERRORS FOUND");
		Dialog.addMessage("The following errors require your attention:\n");
		Dialog.addMessage(errorText);
		Dialog.show();
	}
	
	loop = loop+1;
}

if (startImage < endImage) {
	totalImages = endImage-startImage;
} else if (endImage < startImage) {
	totalImages = startImage-endImage;
	tempStartImage = startImage;
	startImage = endImage;
	endImage = tempStartImage;
}

// Make user select output directory
dir = getDirectory("Choose destination directory for BMP stack");

// If "Create Information File" is selected open new .txt file...
if (createInfoFile == "Yes") {
	f = File.open(dir+"info.txt");
	print(f,"Information File Created: "+currentDate()+"\t");
	print(f,"\t");
	print(f,"---- Setup Information ----\t");
	print(f,"Start Image: "+startImage+"\t");
	print(f,"End Image: "+endImage+"\t");
	print(f,"Output Format: "+outputFormat+"\t");
	print(f,"Run 'Multipy slices by custom value': "+runMultiply+"\t");
	if (runMultiply == "Yes") {
		print(f,"-- Multiply Value: "+multiplyValue+"\t");
	}
	print(f,"Run 'Normalize the Images in the Stack individually': "+runNormalize+"\t");
	if (runNormalize == "Yes") {
		print(f,"-- Saturate Value: "+saturateValue+"\t");	
	}
	print(f,"Run Brightness/Contrast: "+runBrightnessContrast+"\t");
	if (runBrightnessContrast == "Yes" || runBrightnessContrast == "Auto") {
	  	print(f,"-- Min Value: "+minValue+"\t");
	  	print(f,"-- Max Value: "+maxValue+"\t");
	}
	print(f,"Run 'Despeckle': "+runDespeckle+"\t");
	print(f,"Run 'Normalize Stack by Reference Image': "+runNormalizeByReference+"\t");
	if (runNormalizeByReference == "Yes") {
		print(f,"-- Reference Image: "+referenceImageValue+"\t");	
	}
}

// If "Normalize by Reference" has been selected get reference image data...
if(runNormalizeByReference == "Yes") {
	if (selectionType() == -1) run("Select All");
	checkROI(0,3,-1);
	run("Set Slice...", "slice="+referenceImageValue);
	run("Select None");

	run("Restore Selection");
	
	if (runMultiply == "Yes") {
		run("Multiply...", "value="+multiplyValue);
	}
	
	getStatistics(area, mean, min, max, std, histogram);
	meanReference = mean;
	if (createInfoFile == "Yes") {
		print(f,"-- Reference Image Mean: "+meanReference+"\t");
	}
	run("Select None");
}


// Start Batch Processing...
if (createInfoFile == "Yes") {
	print(f,"\t");
	print(f,"---- Batch Process START ----\t");
}

setBatchMode(true);
id = getImageID;
for (i=startImage; i< endImage; i++) {

	if (createInfoFile == "Yes") {
		print(f,"Slice n="+i+"\t");
	}
	
	// Show progress bar
	showProgress(i, endImage);
	
	// Select image and slice, and get file name
	selectImage(id);
	setSlice(i);
	name = getMetadata;
	
	// Duplicate image so we don't write over original
	run("Duplicate...", "title=temp");
	
	if (runMultiply == "Yes") {
		run("Multiply...", "value="+multiplyValue);
		if (createInfoFile == "Yes") {
			print(f,"> Multiply Run\t");
		}
	}
	
	// Run "Normalize Individualy" if selected...
	if(runNormalize == "Yes") {
		run("Enhance Contrast...", "saturated="+saturateValue+" normalize");
		if (createInfoFile == "Yes") {
			print(f,"> Normalize Run\t");
		}
	}
	
	
	// Run "Normalize by Reference Image" if selected...
	if(runNormalizeByReference == "Yes") {
		getStatistics(area, mean, min, max, std, histogram);
		intensityRatio = meanReference / mean;
		
	    if (intensityRatio != 0) {
			  run("Multiply...", "slice value="+intensityRatio);
	    }
		if (createInfoFile == "Yes") {
			print(f,"> Normalize by Reference Run - Mean: "+mean+" Intensity Ratio: "+intensityRatio+"\t");
		}
	}
	
	
	// Run "Brightness/Contrast" if selected...
	if (runBrightnessContrast == "Yes" || runBrightnessContrast == "Auto") {

	  	getMinAndMax(min, max);
	  	oldMin = min;
	  	oldMax = max;
	  	if (runBrightnessContrast == "Auto") {	  		
	  		run("Enhance Contrast...", "saturated=0.35");
	  		//run("Apply LUT", "slice");
	  		getMinAndMax(min, max);
	  		newMin = min;
	  		newMax = max;
	  		if (createInfoFile == "Yes") {
		  		print(f,"> Brightness/Contrast Run - Type: Auto; Old Min: "+oldMin+"; Old Max: "+oldMax+"; New Min: "+newMin+"; New Max: "+newMax+"\t");
		  	}
	  	} else {
	  		setMinAndMax(minValue, maxValue);
	  		//run("Apply LUT", "slice");
	  		getMinAndMax(min, max);
	  		newMin = min;
	  		newMax = max;
	  		if (createInfoFile == "Yes") {
		  		print(f,"> Brightness/Contrast Run - Type: Manual; Old Min: "+oldMin+"; Old Max: "+oldMax+"; New Min: "+newMin+"; New Max: "+newMax+"\t");
		  	}
	  	}
	  	
	}
  	
  	// Run "Despeckle" if selected...
	if (runDespeckle == "Yes") {
		run("Despeckle", "slice");
		if (createInfoFile == "Yes") {
			print(f,"> Despeckle Run\t");
		}
	}

	// Save newly altered file
	if(i<=10) saveAs(outputFormat, dir+"000"+(i-1));
	if(i>10&&i<=100) saveAs(outputFormat, dir+"00"+(i-1));	      
	if(i>100&&i<=1000) saveAs(outputFormat, dir+"0"+(i-1));	      
	if(i>1000) saveAs(outputFormat, dir+(i-1));

	// Deselect everything
	run("Select None");
	
	if (createInfoFile == "Yes") {
		print(f,"\t");
	}
	
	// Close the new file
	close();
}
setBatchMode(false);

// Finish and close the "Information" file if needed
if (createInfoFile == "Yes") {
	print(f,"---- Batch Process END ----\t\t");
	print(f,"Information File Finished: "+currentDate()+"\t");
	File.close(f);
}


}
