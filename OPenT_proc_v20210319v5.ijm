/*
 * OPenT_proc v2021.03. v4  
 * ImageJ macro to pre-process OPenT "raw" projection datasets  
 * created by Gaby G Martins and Nuno P Martins @ Instituto Gulbenkian de Ciência, Oeiras - Portugal
 * For more info on building an OPenT or the latest version of this macro check http://opent.tech/
 * The macro opens a raw dataset, typically several TIFs or a stack of equally spaced angles over a full rotation 
 * and processes them in preparation for filtered backprojection reconstruction using eg, the NRecon tool
 * This macro corrects for sample tilt, centers FOV and cleans noisy pixels and saves a metadata *_.log file
 * There is also a routine in the end to retrieve the stack of reconstructed slices and post-process.
 * Send comments, bug reports or suggestions to gaby@igc.gulbenkian.pt
 */

print("\\Clear");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("Start time"+hour+":"+minute+":"+second);

saveSettings(); //saves settings in edit options so that they can be restored at the end
run("Input/Output...", "jpeg=95 gif=-1 file=.txt use use_file save copy_row save_column save_row"); // TIFFs must be saved in Intel byte order otherwise nrecon does not work!
roiManager("reset");
run("Collect Garbage"); //clears RAM

//////////////////////////////////////////////////

waitForUser(" 'OPenT_proc' [2021] \n============================= \n visit OPenT project at http://opent.tech \n If you find this macro useful please cite our work with OPenT \n \nThis macro pre-processes an OPT 'raw' projection dataset and\nprepares it for FBP as when using an OPenT scanner\nMacro starts by offering to import the sequence of projections.\nIf 'raw' dataset is already loaded just cancel the next step. \n \n  [gaby@igc.gulbenkian.pt]")

run("Image Sequence...");
//open("C:/Users/pcadmin/Desktop/testes.tif");
contrast = "GreenFluor";
//contrast = getString("What is the contrast of this projection dataset?", "GreenFluor");
print("'Channel': "+contrast);

title = getTitle();
print("Image title: "+title);
run("Synchronize Windows");
// This macro assumes images opened are 8 or 16bit gray levels; RGB images must be split/converted before. 

//Do a reslice and play the sinogram movie
//run("Reslice [/]...", "output=0.005 start=Left avoid");
//resl = getTitle();
//run("Animation Options...", "speed=27");
//doCommand("Start Animation [\\]");
//run("Tile");
//beep();
//waitForUser("Please check if the sinogram is OK.\nIf it's not, consider re-acquiring the sample");
//close(resl);
//run("Collect Garbage"); //clears RAM

// Starts by removing outliers to avoid ringing artifacts in final reconstruction
// selects pixels on a frame at the edge of image to estimate background, set as background gray level 
run("Select All"); run("Enlarge...", "enlarge=-5"); run("Make Inverse");
getStatistics(area, mean);
setBackgroundColor(mean, mean, mean);
ThBright = mean/50;  // these values might need to be adjusted for each camera...
ThDark = mean/20;    // these values might need to be adjusted for each camera...
run("Select None");

// ...or replace values for 'ThBright' and 'ThDark' with best value determined empirically
run("Remove Outliers...", "radius=1 threshold="+ThBright+" which=Bright stack");
run("Remove Outliers...", "radius=1 threshold="+ThDark+" which=Dark stack");

// FLIR Rotation
run("Rotate 90 Degrees Left");

// BARREL DISTORTION CORRECTION...UNDER CONSTRUCTION!

// FLAT-FIELD CORRECTION AND BACKGROUND SUBTRACTION ...UNDER CONSTRUCTION! look into Birk et al2012 polynomial fit 
// This is tricky and inconsistent when samples are in agarose
// the best is to optimize illumination and apply a log to gray levels

getDimensions(width, height, channels, slices, frames); //gets image widht and height
makeLine(width/2, height*0.05, width/2, height*0.95);  // draws midline (shoudl coincide with axis of rot.)

// PART TO ADD TO MACRO TO REDUCE BACKGROUNG, FUZZYNESS AND INCREASE CONTRAST AND RESOLUTION
// THIS WAS TESTED AT THE LAST STEP BEFORE NRECON, BUT MAY BE APPLICABLE IN OTHER 
// MAY NEED TO MAKE AN ASSESSMENT OF THE IDEAL ROLLING BAL SIZE, BUT WORKS WELL WITH THIS IN THE NEW CONFIG
run("Subtract Background...", "rolling=300 sliding stack");

//MAY NEED TO CHANGE RADIUS BETWEEN 3-5 DEPENDIN ON ACTUAL RESOLTION OF THE ACQUIRED DATASET
run("Unsharp Mask...", "radius=5 mask=0.75 stack");

//THE BgSubt puts different backgrounds on different projections, ideally it would be a polynomail fit done in the very beggining. but was no ytyet able to implement the ideal!
// and this will cause edge/star artifacts during the reconstruction. to avoid it we need to re-normalize the images. Bleach correction does not work. contrast enhacment was the best (though not ideal)
run("Enhance Contrast...", "saturated=0 normalize process_all");
// study how to do this in CLIjrun("Synchronize Windows"); // 'syncwindows' is not macro compatible so the user needs to manually hit "Synchronize All" button!


// Prepare Z projections used to determine axis tilt + FOV center and crop (ROI)
selectWindow(title);
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
selectWindow(title);
run("Z Project...", "projection=[Min Intensity]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
selectWindow(title);
run("Z Project...", "projection=[Standard Deviation]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
run("Tile");

setTool("line"); //line selection
beep();
waitForUser("<= Make sure you hit the [ Syncronize All ] button before proceeding\n     ===============================\nWith all windows 'Synchronized', adjust the midline so it coincides \nwith the axis of rot. in one of the projected images, then click OK.\nMidline should show in all; zoom if necessary!");
roiManager("Add");
roiManager("Select", 0);
roiManager("Rename", "rotationAxisbefore");

close("MAX_"+title);
close("MIN_"+title);
close("STD_"+title);

List.setMeasurements;
tilt = List.getValue("Angle");
print("Rotation axis tilt: "+tilt);

if (tilt < 0) {
	difference = 90-sqrt(pow(tilt,2));
} else if (tilt > 0) {
	difference = -(90-tilt);
	if (difference > 0) {
		print("Check camera or motor axis tilt!!! \nThe tilt was corrected for this projection dataset");
	};
};
print("Tilt deviation: "+difference);
run("Select None");

selectWindow(title);
run("Rotate... ", "angle="+difference+" grid=0 interpolation=None enlarge stack");
setColor(mean);
setBatchMode("hide");
for (i = 1; i < slices+1; i++) {
	Stack.setSlice(i);
	floodFill(1, 1);
	floodFill(width-1, 1);
	floodFill(0, height-1);
	floodFill(width-1, height-1);
}
setBatchMode("exit and display");


selectWindow(title);
run("Z Project...", "projection=[Min Intensity]");
run("Enhance Contrast...", "saturated=0.4 normalize");
setAutoThreshold("Li dark"); //depending on the dynamics of each camera this algorithm may have to be changed
run("Create Selection");
run("To Bounding Box");
resetMinAndMax();
selectWindow(title);
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
selectWindow(title);
run("Z Project...", "projection=[Standard Deviation]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
selectWindow(title);
run("Restore Selection");
run("Tile");

beep();
waitForUser("Synchronize All! \nAdjust FOV bounding box to projection image(s). \nMove side handles until top/bottom handles coincide with axis of symmetry \nThen CTL+clik side handles to enlarge box symmetrically");
// resetting the display is not working...
resetMinAndMax(); 

roiManager("Add");
roiManager("Select", 1);
roiManager("Rename", "CropBox");
selectWindow(title);
run("Restore Selection");
run("Crop");
close("MAX_"+title);
close("MIN_"+title);
close("STD_"+title);

// CONFIRM ALIGNMENT OF 0º and flipped 180º

getDimensions(width, height, channels, slices, frames);
HSlice=slices/2;
FSlice=slices;
HSlice=round(HSlice);

selectWindow(title);
run("Make Substack...", "  slices=1");
rename("ImageOne");
ImageOne=getTitle();

selectWindow(title);
run("Make Substack...", "  slices="+HSlice);
rename("ImageTwo");
ImageTwo=getTitle();

run("Flip Horizontally", ImageTwo);
run("Merge Channels...", "c2="+ImageOne+" c6="+ImageTwo+" create");
selectWindow("Composite");
rename("ImageThree");
HalfMergeImage=getTitle();

selectWindow(title);
run("Make Substack...", "  slices=1");
rename("ImageOne");
ImageOne=getTitle();

selectWindow(title);
run("Make Substack...", "  slices="+FSlice);
rename("ImageTwo");
ImageTwo=getTitle();

run("Merge Channels...", "c1="+ImageOne+" c5="+ImageTwo+" create");
selectWindow("Composite");
rename("ImageFour");
FullMergeImage=getTitle();

run("Tile");
waitForUser("Check alignment\nFirst window is stack\nsecond window is slices 0 and 180\nthird window is 0 and 360");
selectWindow(HalfMergeImage);
close(HalfMergeImage);
selectWindow(FullMergeImage);
close(FullMergeImage);


// Query to apply "log" to gray levels then scale to 16bit
query = getBoolean("Wish to apply a 'log' function to the \nprojections to enhance dimer pixels?");
if (query == true) {
selectWindow(title);
run("32-bit");
run("Log", "stack");
Stack.getStatistics(voxelCount, mean, min, max, stdDev);
setMinAndMax(min, max+1); //to avoid pixel saturation
};

// Query to invert stack if dark-field/fluorescence (NRecon requires absorptive projectional images)
query = getBoolean("Is this fluorescence/dark-field? \nWill be inverted if you press 'Yes'");
if (query == true) {
	run("Invert", "stack");
};
run("16-bit"); setMinAndMax(0, 65535);

// add to query possibility of top reslicing the proj dataset to present as sinograms for other FBP tools
// under construction 

title=getTitle();
selectWindow(title);
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
selectWindow(title);
run("Z Project...", "projection=[Min Intensity]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
selectWindow(title);
run("Z Project...", "projection=[Standard Deviation]");
run("Enhance Contrast...", "saturated=0.4 normalize");
run("Restore Selection");
run("Tile");
beep();
waitForUser("Check the datasets for inconsistencies!");
close("MAX_"+title);
close("MIN_"+title);
close("STD_"+title);

//saving corrected projections in new folder
chosendir = getDirectory("Choose a Directory to save the processed projectional dataset");
fs = File.separator;
contrast = "GreenFluor";
save_dir = chosendir+"OPTrecon_"+contrast+fs;
File.makeDirectory(save_dir);
print("Image save folder:" +save_dir);
run("Image Sequence... ", "format=TIFF name=proj_ save=["+save_dir+"proj_0000.tif]");

// dialog parameter initialization and creating a metadata 'proj_.log' file
date = "2021-xx-xx";
height = getHeight();
opt_axis = round(height/2);
slices = nSlices();
rotation_step = 360/slices;
mag = 0.465; 
cam = "Mycamera";    // replace here with your camera model to make it automatic
camPixelSize = 3.69;  //FLIR Grasshopper camera's physical pixel size
bitdepth = bitDepth();
exposure = 100;

Dialog.create("OPT projectional dataset metadata...");
Dialog.addMessage("Sample info:");
Dialog.addString("Date of acquisition", date, 30);
Dialog.addString("Sample", "sample", 40);
Dialog.addString("Contrast", contrast, 40);
Dialog.addString("Author", "operator", 40);
Dialog.addMessage("OPT settings:");
Dialog.addNumber("Bit depth", bitdepth);
Dialog.addNumber("Number of projections", slices);
Dialog.addNumber("Rotation step (deg)", rotation_step);
Dialog.addMessage("IMPORTANT! make you insert correct 'mag' here:");
Dialog.addNumber("Mag. (x)", mag);
Dialog.addNumber("Exposure (ms)", exposure);
Dialog.addString("Optics/filters", "optics", 40);
Dialog.show();
date = Dialog.getString();
sample = Dialog.getString();
contrast = Dialog.getString();
operator = Dialog.getString();
bitdepth = Dialog.getNumber();
slices = Dialog.getNumber();
rotation_step = Dialog.getNumber();
mag = Dialog.getNumber();
exposure = Dialog.getNumber();
optics = Dialog.getString();
pixelSize = camPixelSize/mag;

//writing proj_.log file in save dir, first checks if file exists and asks to overwrite
fileList = getFileList(save_dir);
if (File.exists(save_dir+fs+"proj_.log") == 1) {
	check = getBoolean("File already exists, do you want to overwrite it?");
	if (check == 1) {
		File.delete(save_dir+fs+"proj_.log");
	} else {
		exit();
	}
};

f = File.open(save_dir+"\\proj_.log");
print(f, "[System] \r\nScanner=___OPenT__.v2 \r\nInstrument S/N=2 \r\n[Acquisition] \r\nDepth (bits)=16 \r\nOptical Axis (line)="+opt_axis+" \r\nObject to Source (mm)=10000001 \r\nNumber of Files="+slices+" \r\nLinear pixel value="+camPixelSize+" \r\nScaled Image Pixel Size (um)="+pixelSize+" \r\nExposure (ms)="+exposure+" \r\nRotation Step (deg)="+rotation_step+" \r\nUse 360 Rotation=YES \r\nFlat Field Correction=ON \r\nRotation Direction=CC \r\nType of Detector Motion=STEP AND SHOOT \r\nStudy Date and Time="+date+" \r\n;Optics= "+mag+"x magnification \r\n;Channel/contrast: "+contrast+" \r\n;Camera= "+cam+" \r\n;Sample= "+sample+" \r\n;Optics = "+optics+" \r\n;Operator= "+operator+" ");

File.close(f);

run("Close All");
run("Collect Garbage"); //clears RAM

print("Pre-processing Finished. If using NRecon, simply load 'proj_0000.TIF' file...");

//////////////////////////////////////////

beep();
waitForUser("Now switch to NRecon or other tool and reconstruct the optical slices;\n(in NRecon simply open the file 'proj_0000.tif'...). After reconstruction \nclick OK here to post-process the 3D stack or 'Esc' now to finish macro...");

// Query to retrieve stack of reconstructed slices and post-process
query = getBoolean("Retrieve stack of slices and post-process?");
if (query == true) {
run("Image Sequence..."); // allows opening of the sequence of slices
rename("stack"); 
run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast", "saturated=0.35");
rename("MIP");
setTool("freehand");
setAutoThreshold("Li dark"); // tries to identify the sample to trim out 'empty' space
run("Create Selection");
run("To Bounding Box");
beep();
waitForUser("accept ROI or manually contour the sample to trim empty space, then press OK"); // allows user to hand-draw ROI if not happy
selectWindow("stack"); run("Restore Selection"); run("Crop"); // removes empty space
selectWindow("MIP"); close();
selectWindow("stack"); 
run("Properties...", "unit=um pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth="+pixelSize+"");
run("Select None");
run("Reslice [/]...", "output=1.000 start=Top avoid"); // changes from axial to coronal/sagittal slices (same view as OPT camera)
selectWindow("stack"); close();
rename("Resliced");
run("Orthogonal Views");  // display stack as 3D orthogonal views
	// Query to enhance low intensities with a 'gamma' function; necessary often to equalize the stack.
	query = getBoolean("Wish to apply a 'gamma [0.75]' function\nto  enhance dimmer voxels?");
	if (query == true) {
	selectWindow("Resliced"); 
	run("Gamma...", "value=.75 stack");
	}
	print("stack of optical slices enhanced by post.processing");
}
print("Done! bye...");

print("Start time"+hour+":"+minute+":"+second);
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("Finish time"+hour+":"+minute+":"+second);
run("Collect Garbage"); //clears RAM

restoreSettings(); // restores settings in edit options
